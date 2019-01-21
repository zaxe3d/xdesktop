import argparse
from aead import AEAD

parser = argparse.ArgumentParser(description="NFC material tag writer")

parser.add_argument('--in', dest="inFile", default="")
parser.add_argument('--key', dest="key", default="")

args = parser.parse_args()



def decrypt(password, infile):
    cryptor = AEAD(b'5TcXLQkWEpRxzCMvXXOU0M7hmM3wbpEyTxaRgbg5sQM=')
    with open(infile, 'r', encoding='utf-8') as ifile:
        ciphertext = ifile.read()
        print(ciphertext)
        plaintext = cryptor.decrypt(ciphertext[5:], bytes(password, encoding='utf-8'))
        print(plaintext.decode('utf-8'))

if args.inFile != "" and args.key!= "":
    print("will decrypt {0} with key: {1}".format(args.inFile, args.key))
    decrypt(args.key, args.inFile)
else:
    print("check parameters and try again please...")

