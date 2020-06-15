#/bin/bash

function encrypt {
    echo "encrypting [$1]"
    python encrypt_config.py --in ../resources/$1/$2 --out ../../xdesktop-binary-data/cura/resources/$1/$2 --key www.zaxe.com
}

definitions=( "zaxe.def.json" "zaxe_x1.def.json" "zaxe_x2.def.json" "zaxe_x1plus.def.json" "zaxe_z.def.json" "zaxe_z1.def.json" "zaxe_z1plus.def.json" )

for def in "${definitions[@]}"
do
    encrypt "definitions" $def
done

#extruders=( "zaxe_x1_extruder_0.def.json" "zaxe_x1plus_extruder_0.def.json" "zaxe_z1_extruder_0.def.json" "zaxe_z1plus_extruder_0.def.json" )
#
#for def in "${extruders[@]}"
#do
#    encrypt "extruders" $def
#done

variants=( "zaxe_x1_0.4.inst.cfg" "zaxe_x2_0.15_am.inst.cfg" "zaxe_x2_0.25_am.inst.cfg" "zaxe_x2_0.4_am.inst.cfg" "zaxe_x2_0.4.inst.cfg" "zaxe_x1_0.6.inst.cfg" "zaxe_x1_0.8.inst.cfg" "zaxe_x1plus_0.4.inst.cfg" "zaxe_z1_0.2.inst.cfg"  "zaxe_z1_0.4.inst.cfg" "zaxe_z1_0.6.inst.cfg" "zaxe_z1_0.8.inst.cfg" "zaxe_z1_e3d_brass_0.4.inst.cfg" "zaxe_z1plus_0.2.inst.cfg" "zaxe_z1plus_0.4.inst.cfg"  "zaxe_z1plus_0.6.inst.cfg" "zaxe_z1plus_0.8.inst.cfg" "zaxe_z1plus_e3d_brass_0.4.inst.cfg" )

for def in "${variants[@]}"
do
    encrypt "variants" $def
done

qualities=( "expert.inst.cfg" "high.inst.cfg" "recommended.inst.cfg" "fast.inst.cfg" "draft.inst.cfg" "low.inst.cfg"
            "zaxe_z/0.2/0.2_expert.inst.cfg" "zaxe_z/0.2/0.2_high.inst.cfg" "zaxe_z/0.2/0.2_recommended.inst.cfg" "zaxe_z/0.2/0.2_fast.inst.cfg" "zaxe_z/0.2/0.2_draft.inst.cfg" "zaxe_z/0.2/0.2_low.inst.cfg"
            "zaxe_z/0.4/0.4_expert.inst.cfg" "zaxe_z/0.4/0.4_high.inst.cfg" "zaxe_z/0.4/0.4_recommended.inst.cfg" "zaxe_z/0.4/0.4_fast.inst.cfg" "zaxe_z/0.4/0.4_draft.inst.cfg" "zaxe_z/0.4/0.4_low.inst.cfg"
            "zaxe_z/0.6/0.6_fast.inst.cfg" "zaxe_z/0.6/0.6_draft.inst.cfg" "zaxe_z/0.6/0.6_low.inst.cfg"
            "zaxe_z/0.8/0.8_expert.inst.cfg" "zaxe_z/0.8/0.8_high.inst.cfg" "zaxe_z/0.8/0.8_recommended.inst.cfg" "zaxe_z/0.8/0.8_fast.inst.cfg" "zaxe_z/0.8/0.8_draft.inst.cfg" "zaxe_z/0.8/0.8_low.inst.cfg" "zaxe_z/0.8/0.8_lowest.inst.cfg"
          )
for quality in "${qualities[@]}"
do
    encrypt "quality" $quality
done

materials=( "custom.xml.fdm_material" "zaxe_abs.xml.fdm_material" "zaxe_flex_black.xml.fdm_material" "zaxe_flex_white.xml.fdm_material" "zaxe_pla.xml.fdm_material" "zaxe_petg.xml.fdm_material" )

for def in "${materials[@]}"
do
    encrypt "materials" $def
done
