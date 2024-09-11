import sys
import argparse
from antlr4 import *
from .SMTLIBv2Lexer import SMTLIBv2Lexer
from .SMTLIBv2Parser import SMTLIBv2Parser

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('input', nargs='?', type=argparse.FileType('r'), default=sys.stdin)
    args = parser.parse_args()
    run(args)

def run(args):
    text = args.input.read()
    input_stream = InputStream(text)
    lexer = SMTLIBv2Lexer(input_stream)
    stream = CommonTokenStream(lexer)
    parser = SMTLIBv2Parser(stream)
    tree = parser.script()
    if parser.getNumberOfSyntaxErrors() > 0:
        print("syntax errors")
    else:
        print("syntax ok")
