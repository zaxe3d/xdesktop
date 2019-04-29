#/bin/bash

function encrypt {
    echo "encrypting [$1]"
    python encrypt_config.py --in ../resources/$1/$2 --out ../../xdesktop-binary-data/cura/resources/$1/$2 --key www.zaxe.com
}

definitions=( "zaxe.def.json" "zaxe_x1.def.json" "zaxe_x1plus.def.json" "zaxe_z.def.json" "zaxe_z1.def.json" "zaxe_z1plus.def.json" )

for def in "${definitions[@]}"
do
    encrypt "definitions" $def
done

qualities=( "expert.inst.cfg" "fast.inst.cfg" "high.inst.cfg" "low.inst.cfg" "recommended.inst.cfg" )
for quality in "${qualities[@]}"
do
    encrypt "quality" $quality
done
