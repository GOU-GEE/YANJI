// SPDX-License-Identifier: MPL-2.0
// A process-isolated harness for the same in-process mobile engine.
package main
import (
 "bufio"
 "encoding/json"
 "fmt"
 "os"
 "yanji.local/syncthing/engine"
)
func main() {
 scanner:=bufio.NewScanner(os.Stdin); scanner.Buffer(make([]byte,65536),4<<20)
 for scanner.Scan() {
  result,err:=engine.Execute(scanner.Text())
  if err!=nil {b,_:=json.Marshal(map[string]string{"error":err.Error()});fmt.Println(string(b))} else {fmt.Println(result)}
 }
 engine.Execute("{\"command\":\"stop\"}")
}
