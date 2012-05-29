# Derived from http://aspn.activestate.com/ASPN/Cookbook/Python/Recipe/438823
# with __init__() code taken from comments of Brodie R., in
# http://aspn.activestate.com/ASPN/Cookbook/Python/Recipe/496761

import types

class odict(dict):

    def __init__(self, *args, **kwds):
        dict.__init__(self, *args, **kwds)
        self._keys = []
        if len(args) == 1:
            d = args[0]
            if hasattr(d, 'items'):
                items = d.items()
            else:
                items = list(d)
            for i in xrange(len(items)):
                self._keys.append(items[i][0])
        if kwds:
            self._merge_keys(kwds.iterkeys())
            self.update (kwds)

    def __delitem__(self, key):
        dict.__delitem__(self, key)
        self._keys.remove(key)

    def __setitem__(self, key, item):
        dict.__setitem__(self, key, item)
        # a peculiar sharp edge from copy.deepcopy
        # we'll have our set item called without __init__
        if not hasattr(self, '_keys'):
            self._keys = [key,]
        if key not in self._keys:
            self._keys.append(key)

    def __iter__(self):
        for k in self._keys:
            yield k

    def __repr__(self):
        result = []
        for key in self._keys:
            result.append('(%s, %s)' % (repr(key), repr(self[key])))
        return ''.join([self.__class__.__name__, '([', ', '.join(result), '])'])

    def clear(self):
        dict.clear(self)
        self._keys = []

    def items(self):
        return [(k,self[k]) for k in self._keys]

    def keys(self):
        return self._keys

    def values(self):
        return [self[k] for k in self._keys]

    def iteritems(self):
        for k in self._keys:
            yield (k, self[k])

    def iterkeys(self):
        return self.__iter__()

    def itervalues(self):
        for k in self._keys:
            yield self[k]

    def update(self, data):
        if data is not None:
            if hasattr(data, 'iterkeys'):
                self._merge_keys(data.iterkeys())
            else:
                self._merge_keys(data.keys())
            dict.update(self,data)

    def setdefault(self, key, failobj = None):
        dict.setdefault(self, key, failobj)
        if key not in self._keys:
            self._keys.append(key)

    def index(self, key):
        if key not in self:
            raise KeyError(key)
        return self._keys.index(key)

    def popitem(self):
        if len(self._keys) == 0:
            raise KeyError('dictionary is empty')
        else:
            key = self._keys[-1]
            val = self[key]
            del self[key]
            return key, val

    def move(self, key, index):
        "Move the specified key to before the specified index."
        try:
            cur = self._keys.index(key)
        except ValueError:
            raise KeyError(key)
        self._keys.insert(index, key)
        # this may have shifted the position of cur, if it is after index
        if cur >= index: cur = cur + 1
        del self._keys[cur]

    def atpos (self, index):
        "Return the item (key, value pair as tuple) at position 'index'."
        # odict[index]
        k = self._keys[index]
        return k,self[k]

    def setpos (self, index, item):
        # odict[index] = item
        newkey, newval = item
        oldkey = self._keys[index]
        if oldkey != newkey:
            if newkey in self: raise KeyError (("Duplicate key: %r" % newkey), newkey)
            self._keys[index] = newkey
            dict.__delitem__ (self, oldkey)
        dict.__setitem__(self, newkey, item[1])

    def delpos (self, index):
        del self[self._keys[index]]
        del self._keys[index]

    def changekey (self, index, newkey):
        "Change the key at position 'index' to 'newkey'."
        oldkey = self._keys[index]
        if newkey != oldkey:
            if newkey in self: raise KeyError (("Duplicate key: %r" % newkey), newkey)
            v = self[oldkey]
            self._keys[index] = newkey
            self[newkey] = v
            dict.__delitem__ (self, oldkey)

    def _merge_keys(self, keys):
        self._keys.extend(keys)
        newkeys = {}
        self._keys = [newkeys.setdefault(x, x) for x in self._keys
                                               if x not in newkeys]

# overwridden dict methods
#   __delitem__, __setitem__, __iter__, __repr__, clear, items, keys, values,
#   iteritems, iterkeys, itervalues, update, setdefault, popitem,
# Inherited from dict():
#    copy, has_key, get, pop
# List-ish methods:
#    index
# Unique methods:
#    move, k,v=atpos(i), chgkey(i,newkey)
# To-do???:
#    slices?, reverse, sort, insert(i,k,v)