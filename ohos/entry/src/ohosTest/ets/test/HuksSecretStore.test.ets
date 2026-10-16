import { describe, it, expect } from '@ohos/hypium';
import common from '@ohos.app.ability.common';
import huks from '@ohos.security.huks';
import preferences from '@ohos.data.preferences';
import util from '@ohos.util';
import { BusinessError } from '@ohos.base';
import { HuksSecretStore, SecretStoreLocation } from '../../../main/ets/platform/HuksSecretStore';

interface SealedFixture {
  version: number;
  nonce: string;
  ciphertext: string;
}
const identityKey: string = 'yanji.identity.v1';
const tlsKey: string = 'yanji.tls.identity.v1';
const endpointKey: string = 'yanji.sync.endpoints.v1';
const plaintext: string = '合成测试身份：not-a-real-private-key';
const replacement: string = 'replacement-must-never-be-written';
const prefix: string = 'yanji.acceptance.huks.';

async function keyExists(alias: string): Promise<boolean> {
  try {
    return await huks.isKeyItemExist(alias, { properties: [] });
  } catch (error) {
    if ((error as BusinessError).code === 12000011) return false;
    throw new Error('Unexpected HUKS lookup failure');
  }
}
async function rejectsRead(store: HuksSecretStore, key: string): Promise<void> {
  let rejected: boolean = false;
  try { await store.read(key); } catch (_) { rejected = true; }
  expect(rejected).assertTrue();
}
async function rejectsWrite(store: HuksSecretStore, key: string): Promise<void> {
  let rejected: boolean = false;
  try { await store.write(key, replacement); } catch (_) { rejected = true; }
  expect(rejected).assertTrue();
}

let sequence: number = 0;
async function usingStore(context: common.Context,
  work: (store: HuksSecretStore, prefs: preferences.Preferences,
    location: SecretStoreLocation) => Promise<void>): Promise<void> {
  const name: string = prefix + Date.now().toString() + '.' + (++sequence).toString();
  const location: SecretStoreLocation = { preferencesName: name, keyAlias: name };
  const store = new HuksSecretStore(context, location);
  const prefs = preferences.getPreferencesSync(context, { name: name });
  try {
    await store.write(identityKey, plaintext);
    await work(store, prefs, location);
  } finally {
    // Only delete the exact disposable location created by this test case.
    expect(location.keyAlias.startsWith(prefix)).assertTrue();
    expect(location.preferencesName.startsWith(prefix)).assertTrue();
    if (await keyExists(location.keyAlias)) {
      await huks.deleteKeyItem(location.keyAlias, { properties: [] });
    }
    await preferences.deletePreferences(context, { name: location.preferencesName });
  }
}

export default function huksSecretStoreTest(context: common.Context) {
  describe('YanjiHuksSecretStore', () => {
    const base64 = new util.Base64Helper();
    it('roundTripUtf8TlsSizedValueAndFreshNonce', 0, async () => usingStore(context, async (store, prefs, location) => {
      const raw: string = await prefs.get(identityKey, '') as string;
      expect(raw.includes(plaintext)).assertFalse();
      expect(await store.read(identityKey)).assertEqual(plaintext);
      await store.write(identityKey, plaintext);
      const rewritten: string = await prefs.get(identityKey, '') as string;
      const first = JSON.parse(raw) as SealedFixture;
      const second = JSON.parse(rewritten) as SealedFixture;
      expect(first.nonce === second.nonce).assertFalse();
      expect(first.ciphertext === second.ciphertext).assertFalse();
      const tlsSized: string = 'synthetic-tls-credential-'.repeat(200);
      await store.write(tlsKey, tlsSized);
      const reopened = new HuksSecretStore(context, location);
      expect(await reopened.read(tlsKey)).assertEqual(tlsSized);
      expect(await reopened.read(endpointKey)).assertNull();
    }));

    it('invalidJsonRefusesReadAndReplacement', 0, async () => usingStore(context, async (store, prefs, location) => {
      await prefs.put(identityKey, '{broken');
      await prefs.flush();
      await rejectsRead(store, identityKey);
      await rejectsWrite(store, identityKey);
      expect(await prefs.get(identityKey, '')).assertEqual('{broken');
      expect(await keyExists(location.keyAlias)).assertTrue();
    }));

    it('unsupportedVersionPreservesRecord', 0, async () => usingStore(context, async (store, prefs, location) => {
      const record = JSON.parse(await prefs.get(identityKey, '') as string) as SealedFixture;
      record.version = 99;
      const raw: string = JSON.stringify(record);
      await prefs.put(identityKey, raw);
      await prefs.flush();
      await rejectsRead(store, identityKey);
      await rejectsWrite(store, identityKey);
      expect(await prefs.get(identityKey, '')).assertEqual(raw);
    }));

    it('ciphertextBitFlipFailsAuthenticationAndCanRecoverOriginal', 0, async () => usingStore(context, async (store, prefs, location) => {
      const original: string = await prefs.get(identityKey, '') as string;
      const record = JSON.parse(original) as SealedFixture;
      const data: Uint8Array = base64.decodeSync(record.ciphertext);
      data[0] = data[0] ^ 1;
      record.ciphertext = base64.encodeToStringSync(data);
      const corrupted: string = JSON.stringify(record);
      await prefs.put(identityKey, corrupted);
      await prefs.flush();
      await rejectsRead(store, identityKey);
      await rejectsWrite(store, identityKey);
      expect(await prefs.get(identityKey, '')).assertEqual(corrupted);
      await prefs.put(identityKey, original);
      await prefs.flush();
      expect(await store.read(identityKey)).assertEqual(plaintext);
    }));

    it('invalidNonceAndTruncatedTagPreserveCiphertext', 0, async () => usingStore(context, async (store, prefs, location) => {
      const original: string = await prefs.get(identityKey, '') as string;
      const record = JSON.parse(original) as SealedFixture;
      record.nonce = base64.encodeToStringSync(new Uint8Array(1));
      const invalidNonce: string = JSON.stringify(record);
      await prefs.put(identityKey, invalidNonce);
      await prefs.flush();
      await rejectsRead(store, identityKey);
      await rejectsWrite(store, identityKey);
      expect(await prefs.get(identityKey, '')).assertEqual(invalidNonce);
      const truncated = JSON.parse(original) as SealedFixture;
      truncated.ciphertext = base64.encodeToStringSync(new Uint8Array(15));
      const invalidTag: string = JSON.stringify(truncated);
      await prefs.put(identityKey, invalidTag);
      await prefs.flush();
      await rejectsRead(store, identityKey);
      await rejectsWrite(store, identityKey);
      expect(await prefs.get(identityKey, '')).assertEqual(invalidTag);
    }));

    it('swappingIdentityAndTlsRecordsFailsAadAuthentication', 0, async () => usingStore(context, async (store, prefs, location) => {
      await store.write(tlsKey, 'synthetic-tls-secret');
      const identity: string = await prefs.get(identityKey, '') as string;
      const tls: string = await prefs.get(tlsKey, '') as string;
      await prefs.put(identityKey, tls);
      await prefs.put(tlsKey, identity);
      await prefs.flush();
      await rejectsRead(store, identityKey);
      await rejectsRead(store, tlsKey);
      await rejectsWrite(store, identityKey);
      await rejectsWrite(store, tlsKey);
      expect(await prefs.get(identityKey, '')).assertEqual(tls);
      expect(await prefs.get(tlsKey, '')).assertEqual(identity);
    }));

    it('lostWrappingKeyNeverRekeysOrOverwritesExistingSecrets', 0, async () => usingStore(context, async (store, prefs, location) => {
      const original: string = await prefs.get(identityKey, '') as string;
      await huks.deleteKeyItem(location.keyAlias, { properties: [] });
      await rejectsRead(store, identityKey);
      await rejectsWrite(store, identityKey);
      // A different, absent record must not trigger key recreation either.
      await rejectsWrite(store, tlsKey);
      expect(await keyExists(location.keyAlias)).assertFalse();
      expect(await prefs.get(identityKey, '')).assertEqual(original);
      expect(await prefs.has(tlsKey)).assertFalse();
    }));

    it('unsupportedNamesCannotReadOrWritePreferences', 0, async () => usingStore(context, async (store, prefs, location) => {
      await rejectsRead(store, 'unsupported-key');
      await rejectsWrite(store, 'unsupported-key');
      expect(await prefs.has('unsupported-key')).assertFalse();
      expect(await store.read(identityKey)).assertEqual(plaintext);
    }));
  });
}
