# This code is modified from a nimcrypto code example.

#
#
#                    NimCrypto
#        (c) Copyright 2016-2018 Eugene Kabanov
#
#      See the file "LICENSE", included in this
#    distribution, for details about the copyright.
#

## This is example of usage ``GCM[T]`` encryption/decryption.
##
## In this sample we are using GCM[AES256], but you can use any block
## cipher from nimcrypto library.
import json
import nimcrypto

type
  AESConfig* = ref object of RootObj
    key*: string
    iv*: string
    aad*: string

proc newAESConfig*(key, aad, iv: string): AESConfig =
  new(result)

  assert len(key) > 0
  assert len(aad) > 0
  assert len(iv) > 0

  result.key = key
  result.aad = aad
  result.iv = iv

proc getAESConfig*(configPath: string): AESConfig =
  var config = parseJson(readFile(configPath))
  return newAESConfig(
    config["aes_secret_key"].getStr(),
    config["aes_secret_aad"].getStr(),
    config["aes_secret_iv"].getStr()
  )

proc decryptTextAES*(config: AESConfig, hexEncryptedStr: string): string =
  var dctx: GCM[aes256]
  var key: array[aes256.sizeKey, byte]
  var iv: array[aes256.sizeBlock, byte]
  var aadText = newSeq[byte](len(config.aad))

  # We don not need to pad AAD data too.
  copyMem(addr aadText[0], addr config.aad[0], len(config.aad))

  # AES256 key size is 256 bits or 32 bytes, so we need to pad key with
  # 0 bytes.
  # WARNING! Do not use 0 byte padding in applications, this is done
  # as example.
  copyMem(addr key[0], addr config.key[0], len(config.key))

  # Initial vector IV size for GCM[aes256] is equal to AES256 block size 128
  # bits or 16 bytes.
  copyMem(addr iv[0], addr config.iv[0], len(config.iv))

  # Initialization of GCM[aes256] context with encryption key.
  dctx.init(key, iv, aadText)
  # Decryption process
  # In `GCM` mode there no need to pad encrypted data.
  let encStr = fromHex(hexEncryptedStr)
  var decText = newSeq[byte](len(encStr))
  var encText = newSeq[byte](len(encStr))

  # We do not need to pad data, `GCM` mode works byte by byte.
  copyMem(addr encText[0], unsafeAddr encStr[0], len(encStr))

  dctx.decrypt(encText, decText)
  # Obtain authentication tag.
  var dtag: array[aes256.sizeBlock, byte]
  dctx.getTag(dtag)
  # Clear context of CTR[aes256].
  dctx.clear()

  # echo "DECODED TEXT: ", toHex(decText)
  # echo "DECODED TAG: ", toHex(dtag)
  var decStr: string
  for charNum in decText:
    decStr &= chr(charNum)
  return decStr

proc encryptTextAES*(config: AESConfig, secretData: string): string =
  ## Nim's way API using openarray[byte].
  var ectx: GCM[aes256]
  var key: array[aes256.sizeKey, byte]
  var iv: array[aes256.sizeBlock, byte]
  var plainText = newSeq[byte](len(secretData))
  var encText = newSeq[byte](len(secretData))
  var aadText = newSeq[byte](len(config.aad))
  # Authentication tags
  var etag: array[aes256.sizeBlock, byte]

  # We do not need to pad data, `GCM` mode works byte by byte.
  copyMem(addr plainText[0], unsafeAddr secretdata[0], len(secretData))

  # We don not need to pad AAD data too.
  copyMem(addr aadText[0], addr config.aad[0], len(config.aad))

  # AES256 key size is 256 bits or 32 bytes, so we need to pad key with
  # 0 bytes.
  # WARNING! Do not use 0 byte padding in applications, this is done
  # as example.
  copyMem(addr key[0], addr config.key[0], len(config.key))

  # Initial vector IV size for GCM[aes256] is equal to AES256 block size 128
  # bits or 16 bytes.
  copyMem(addr iv[0], addr config.iv[0], len(config.iv))

  # Initialization of GCM[aes256] context with encryption key.
  ectx.init(key, iv, aadText)
  # Encryption process
  # In `GCM` mode there no need to pad plain data.
  ectx.encrypt(plainText, encText)
  # Obtain authentication tag.
  ectx.getTag(etag)
  # Clear context of CTR[aes256].
  ectx.clear()

  # echo "IV: ", toHex(iv)
  # echo "AAD: ", toHex(aadText)
  # echo "PLAIN TEXT: ", toHex(plainText)
  # echo "ENCODED TEXT: ", toHex(encText)
  # echo "ENCODED TAG: ", toHex(etag)

  # Note that if tags are not equal, decrypted data must not be considered as
  # successfully decrypted.
  # assert(equalMem(addr dtag[0], addr etag[0], len(etag)))

  # Compare plaintext with decoded text.
  # assert(equalMem(addr plainText[0], addr decText[0], len(plainText)))
  return toHex(encText)

