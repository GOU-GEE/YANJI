import huks from '@ohos.security.huks';
import cryptoFramework from '@ohos.security.cryptoFramework';
import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import util from '@ohos.util';

// Preferences holds only authenticated ciphertext. The wrapping key is generated
// and retained by HUKS; it is never exported or written to app storage.
interface SealedValue {
  version: number;
  nonce: string;
  ciphertext: string;
}

export class HuksSecretStore {
  private readonly alias: string = 'yanji.secrets.aes256.v1';
  private readonly keys: string[] = [
    'yanji.identity.v1', 'yanji.tls.identity.v1', 'yanji.sync.endpoints.v1'
  ];
  private readonly encoder = new util.TextEncoder();
  private readonly decoder = util.TextDecoder.create('utf-8', { fatal: true });
  private readonly base64 = new util.Base64Helper();
  private readonly prefs: preferences.Preferences;

  constructor(context: common.Context) {
    this.prefs = preferences.getPreferencesSync(context, { name: 'yanji_secrets_v1' });
  }

  private checkKey(key: string): void {
    if (!this.keys.includes(key)) throw new Error('Unsupported secret key');
  }

  private async hasWrappingKey(): Promise<boolean> {
    return huks.isKeyItemExist(this.alias, { properties: [] });
  }

  private async ensureWrappingKey(): Promise<void> {
    if (await this.hasWrappingKey()) return;
    for (const key of this.keys) {
      if (await this.prefs.has(key)) throw new Error('Wrapping key is missing');
    }
    const properties: huks.HuksParam[] = [
      { tag: huks.HuksTag.HUKS_TAG_ALGORITHM, value: huks.HuksKeyAlg.HUKS_ALG_AES },
      { tag: huks.HuksTag.HUKS_TAG_KEY_SIZE, value: huks.HuksKeySize.HUKS_AES_KEY_SIZE_256 },
      { tag: huks.HuksTag.HUKS_TAG_PURPOSE, value:
        huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_ENCRYPT | huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_DECRYPT },
      { tag: huks.HuksTag.HUKS_TAG_PADDING, value: huks.HuksKeyPadding.HUKS_PADDING_NONE },
      { tag: huks.HuksTag.HUKS_TAG_BLOCK_MODE, value: huks.HuksCipherMode.HUKS_MODE_GCM }
    ];
    await huks.generateKeyItem(this.alias, { properties: properties });
  }

  private async crypt(key: string, data: Uint8Array, nonce: Uint8Array,
    decrypt: boolean, authTag?: Uint8Array): Promise<Uint8Array> {
    const properties: huks.HuksParam[] = [
      { tag: huks.HuksTag.HUKS_TAG_ALGORITHM, value: huks.HuksKeyAlg.HUKS_ALG_AES },
      { tag: huks.HuksTag.HUKS_TAG_KEY_SIZE, value: huks.HuksKeySize.HUKS_AES_KEY_SIZE_256 },
      { tag: huks.HuksTag.HUKS_TAG_PURPOSE, value: decrypt ?
        huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_DECRYPT : huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_ENCRYPT },
      { tag: huks.HuksTag.HUKS_TAG_PADDING, value: huks.HuksKeyPadding.HUKS_PADDING_NONE },
      { tag: huks.HuksTag.HUKS_TAG_BLOCK_MODE, value: huks.HuksCipherMode.HUKS_MODE_GCM },
      { tag: huks.HuksTag.HUKS_TAG_NONCE, value: nonce },
      { tag: huks.HuksTag.HUKS_TAG_ASSOCIATED_DATA, value: this.encoder.encodeInto('yanji.secrets.v1:' + key) }
    ];
    if (authTag !== undefined) properties.push({ tag: huks.HuksTag.HUKS_TAG_AE_TAG, value: authTag });
    const options: huks.HuksOptions = { properties: properties, inData: data };
    const session = await huks.initSession(this.alias, options);
    let finished = false;
    try {
      const result = await huks.finishSession(session.handle, options);
      finished = true;
      if (result.outData === undefined) throw new Error('HUKS returned no data');
      return result.outData;
    } finally {
      if (!finished) await huks.abortSession(session.handle, { properties: [] });
    }
  }

  async read(key: string): Promise<string | null> {
    this.checkKey(key);
    if (!await this.prefs.has(key)) return null;
    if (!await this.hasWrappingKey()) throw new Error('Wrapping key is missing');
    const raw = await this.prefs.get(key, '');
    if (typeof raw !== 'string' || raw.length === 0) throw new Error('Invalid secret record');
    const record = JSON.parse(raw) as SealedValue;
    if (record.version !== 1) throw new Error('Unsupported secret version');
    const nonce = this.base64.decodeSync(record.nonce);
    const ciphertext = this.base64.decodeSync(record.ciphertext);
    if (nonce.length !== 12 || ciphertext.length < 16) throw new Error('Invalid secret record');
    const plain = await this.crypt(key, ciphertext.slice(0, -16), nonce, true, ciphertext.slice(-16));
    return this.decoder.decodeToString(plain);
  }

  async write(key: string, value: string): Promise<void> {
    this.checkKey(key);
    // Verify an existing record first: never overwrite corruption or a lost key.
    if (await this.prefs.has(key)) await this.read(key);
    await this.ensureWrappingKey();
    const nonce = cryptoFramework.createRandom().generateRandomSync(12).data;
    const ciphertext = await this.crypt(key, this.encoder.encodeInto(value), nonce, false);
    const record: SealedValue = { version: 1, nonce: this.base64.encodeToStringSync(nonce),
      ciphertext: this.base64.encodeToStringSync(ciphertext) };
    await this.prefs.put(key, JSON.stringify(record));
    await this.prefs.flush();
  }
}
