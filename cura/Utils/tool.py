import random
import os
import re
import urllib.parse

def getRandChar(size=10):
        maxSize = size
        i = 0
        chars = ""
        while i < maxSize:
            chars += random.choice("qwertyuopasdfghjklzxcvbnm")
            i += 1
        return chars

def merge_two_dicts(x, y):
    """Given two dicts, merge them into a new dict as a shallow copy."""
    z = x.copy()
    z.update(y)
    return z

def merge_dicts(*arg):
    final_dict = dict()
    for _dict in arg:
        final_dict.update(_dict)
    return final_dict

def except_dict(dict_, keys):
    ret_dict = dict()
    for key, value in dict_.iteritems():
        if key in keys:
            continue
        ret_dict[key] = value
    return ret_dict

def limit(value, _min, _max):
    return max(min(value, _max), _min)

def override(dict1, overrides):
    _dict = dict1.copy()
    for key, value in overrides.iteritems():
        if type(value) == dict:
            _dict[key] = override(_dict[key], value)
        else:
            _dict[key] = value
    return _dict

def multiply(_dict, multiplier, _min, _max):
    for key, value in _dict.iteritems():
        _dict[key] = limit(value * multiplier, _min, _max)
    return _dict

def translateChars(text):
    translationTable = str.maketrans("ğĞıİöÖüÜşŞçÇ", "gGiIoOuUsScC")
    return text.strip().translate(translationTable)

def baseName(path):
    return urllib.parse.quote(os.path.basename(path))

def eightDot3Filename(path, suffix):
    filename, file_extension = os.path.splitext(baseName(path))                                            
    filename += suffix # to lengthen the filename                                                   
    filename = re.sub('[^0-9a-zA-Z]+', '', filename)
    return "{0}~1{1}".format(filename[:6].upper(), file_extension[:4].upper())

def isNumber(s):
    try:
        float(s)
        return True
    except ValueError:
        return False
