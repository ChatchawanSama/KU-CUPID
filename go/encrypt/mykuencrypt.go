package encrypt

import (
	"crypto/rand"
	"crypto/rsa"
	"crypto/sha1"
	"encoding/base64"
)

var MYKU_RSA_PUBLIC_KEY = `-----BEGIN PUBLIC KEY-----
MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAytOhlq/JPcTN0fX+VqOb
E5kwIaDnEtso2KGHdi9y7uTtQA6pO4fsPNJqtXOdrcfDgp/EQifPwVRZpjdbVrD6
FgayrQQILAnARKzVmzwSMDdaP/hOB6i9ouKsIhN9hQUmUhbhaMkh7UXoxGW+gCSK
8dq0+FJVnlt1dtJByiVAJRi2oKSdLRqNjk8yGzuZ6SrEFzAgYZwmQiywUF6V1ZaM
UQDz8+nr9OOVU3c6Z2IQXCbOv6S7TAg0VhriFL18ZxUPS6759SuKC63VOOSf4EEH
y1m0qBgpCzzlsB7D4ssF9x0ZVXLREFrqikP71Hg6tSGcu4YBKL+VwIDWWaXzz6sz
xeDXdYTA3l35P7I9uBUgMznIjTjNaAX4AXRsJcN9fpF7mVq4eK1CorBY+OOzOc+/
yVBpKysdaV/yZ+ABEhX93B2kPLFSOPUKjSPK2rtqE6h2NSl5BFuGEoVBerKn+ymO
nmE4/SDBSe5S6gIL5vwy5zNMsxWUaUF5XO9Ez+2v8+yPSvQydj3pw5Rlb07mAXcI
18ZYGClO6g/aKL52KYnn1FZ/X3r8r/cibfDbuXC6FRfVXJmzikVUqZdTp0tOwPkh
4V0R63l2RO9Luy7vG6rurANSFnUA9n842KkRtBagQeQC96dbC0ebhTj+NPmskklx
r6/6Op/P7d+YY76WzvQMvnsCAwEAAQ==
-----END PUBLIC KEY-----`
var MYKU_APP_KEY = `txCR5732xYYWDGdd49M3R19o1OVwdRFc`

func EncryptWithRSAPublicKey(text string, pubKey *rsa.PublicKey) (string, error) {
	label := []byte("")
	hash := sha1.New()
	encrypted, err := rsa.EncryptOAEP(hash, rand.Reader, pubKey, []byte(text), label)
	if err != nil {
		return "", err
	}
	return base64.StdEncoding.EncodeToString(encrypted), nil
}
