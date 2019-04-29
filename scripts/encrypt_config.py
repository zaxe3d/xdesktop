import argparse
from aead import AEAD

parser = argparse.ArgumentParser(description="Config file encrypter")

parser.add_argument('--in', dest="inFile", default="")
parser.add_argument('--out', dest="outFile", default="")
parser.add_argument('--key', dest="key", default="")

args = parser.parse_args()



def write_encrypted(password, infile, outfile):
    with open(infile, 'r', encoding='utf-8') as ifile:
        with open(outfile, 'wb') as ofile:
            cryptor = AEAD(b'5TcXLQkWEpRxzCMvXXOU0M7hmM3wbpEyTxaRgbg5sQM=')
            ciphertext = cryptor.encrypt(bytes(ifile.read(), encoding='utf-8'), bytes(password, encoding='utf-8'))
            print(ciphertext)
            ofile.write(b'crypt' + ciphertext)

if args.inFile != ""  and args.outFile != "" and args.key!= "":
    print("will encrypt {0} to {1} with key: {2}".format(args.inFile, args.outFile, args.key))
    write_encrypted(args.key, args.inFile, args.outFile)
else:
    print("check parameters and try again please...")

