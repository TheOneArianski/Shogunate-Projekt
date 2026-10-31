"""Baut build/Shogunate.rbxlx aus default.project.json (ohne Rojo).
Aufruf: python3 tools/build_place.py
Dateiendungen: .server.lua -> Script, .client.lua -> LocalScript, .lua -> ModuleScript
"""
import json, os
from xml.sax.saxutils import escape

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ref_counter = [0]

def ref():
    ref_counter[0] += 1
    return f"RBX{ref_counter[0]:08X}"

def cdata(text):
    return "<![CDATA[" + text.replace("]]>", "]]]]><![CDATA[>") + "]]>"

def item(cls, name, children="", extra=""):
    return (f'<Item class="{cls}" referent="{ref()}"><Properties>'
            f'<string name="Name">{escape(name)}</string>{extra}</Properties>{children}</Item>')

def script_item(path):
    fname = os.path.basename(path)
    if fname.endswith(".server.lua"):
        cls, name = "Script", fname[:-len(".server.lua")]
    elif fname.endswith(".client.lua"):
        cls, name = "LocalScript", fname[:-len(".client.lua")]
    else:
        cls, name = "ModuleScript", fname[:-len(".lua")]
    src = open(path, encoding="utf-8").read()
    return item(cls, name, extra=f'<ProtectedString name="Source">{cdata(src)}</ProtectedString>')

def dir_children(path):
    out = []
    for entry in sorted(os.listdir(path)):
        full = os.path.join(path, entry)
        if os.path.isdir(full):
            out.append(item("Folder", entry, "".join(dir_children(full))))
        elif entry.endswith(".lua"):
            out.append(script_item(full))
    return out

def node(name, spec, default_class="Folder"):
    cls = spec.get("$className", default_class)
    children = []
    if "$path" in spec:
        children += dir_children(os.path.join(ROOT, spec["$path"]))
    for key, sub in spec.items():
        if not key.startswith("$"):
            children.append(node(key, sub))
    return item(cls, name, "".join(children))

def part(cls, name, pos, size, color_argb):
    x, y, z = pos
    cf = (f'<CoordinateFrame name="CFrame"><X>{x}</X><Y>{y}</Y><Z>{z}</Z>'
          '<R00>1</R00><R01>0</R01><R02>0</R02><R10>0</R10><R11>1</R11><R12>0</R12>'
          '<R20>0</R20><R21>0</R21><R22>1</R22></CoordinateFrame>')
    sx, sy, sz = size
    props = (cf + f'<Vector3 name="size"><X>{sx}</X><Y>{sy}</Y><Z>{sz}</Z></Vector3>'
             '<bool name="Anchored">true</bool>'
             f'<Color3uint8 name="Color3uint8">{color_argb}</Color3uint8>')
    return item(cls, name, extra=props)

def main():
    project = json.load(open(os.path.join(ROOT, "default.project.json"), encoding="utf-8"))
    tree = project["tree"]
    services = []
    for key, spec in tree.items():
        if not key.startswith("$"):
            services.append(node(key, spec))
    # Startfläche, damit man sofort testen kann
    workspace = item("Workspace", "Workspace",
                     part("Part", "Baseplate", (0, -0.5, 0), (512, 1, 512), 0xFF5B5B53) +
                     part("SpawnLocation", "SpawnLocation", (0, 0.5, 0), (12, 1, 12), 0xFFA3A2A5))
    xml = ('<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" '
           'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
           'xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">'
           + workspace + "".join(services) + "</roblox>")
    os.makedirs(os.path.join(ROOT, "build"), exist_ok=True)
    out = os.path.join(ROOT, "build", "Shogunate.rbxlx")
    open(out, "w", encoding="utf-8").write(xml)
    print("geschrieben:", out)

if __name__ == "__main__":
    main()
