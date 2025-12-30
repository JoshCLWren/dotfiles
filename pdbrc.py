import pdb
from pprint import pformat

if hasattr(pdb, "DefaultConfig"):

    class Config(pdb.DefaultConfig):
        sticky_by_default = True
        prompt = "(Pdb) "

        def setup(self, pdb_obj):
            def pretty_displayhook(value):
                if value is not None:
                    pdb_obj.message(pformat(value))

            pdb_obj.displayhook = pretty_displayhook
