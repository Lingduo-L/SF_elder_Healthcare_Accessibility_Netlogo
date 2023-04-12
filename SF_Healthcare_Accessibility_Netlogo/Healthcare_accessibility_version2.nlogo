extensions [ gis Csv palette]

globals [
  accessibility-index-reserve ; used in the creation of the accessibility index
  senior-clinics-dataset
  non-senior-clinics-dataset
  censusBlocks-dataset
  boundary
  GEOID-list
  ct-patient-num-list
  ct-patient-A-num-list
  ct-A-list
  senior-pops
  num-patients
  num-patients-today
  temp-ct-num-patients
  res
]

patches-own [
  tract-id ; the unique ID associated with each census block
  education ; the education percentage from the census dataset
  senior-in-ct ; the senior population from the census dataset
  OBJECTID
  poverty ; the poverty percentage from the census dataset
  disability ; the 1+ persons with disability percentage of household from the census dataset
  healthInsurance ; the percentage of senior people with 1 type of health insurance
  patient-here? ; is TRUE if there is a person on the patch...used in the creation of the population of people
  Clinic-here?
  seniorClinic-here? ; marked TRUE if there is a senior clinic on the patch
  clinic-name
  preference
  cancerValue
  highBloodPressure
  diabetesValue
  h-num-physicians
  h-positions ; how many position rn
  patient-A-num
  num-patients-in-patch
]

breed [patients patient ]
patients-own [
  p-edu ;
  fs ;
  p-pov ;
  p-disability
  p-health_ins
  healthcare-facilities-in-radius
;  patient-A? ; a person whether receive healthcare services or not
  my-GEOID
  p-cancer
  p-bpHigh
  p-diabetes
  patient-healthcare-facility
  patient-arrive-time
  patient-duration
  move?
]
breed [healthcare-facilities healthcare-facility]
healthcare-facilities-own [
;  h-num-physicians
;  h-positions ; how many position rn
]

to setup ; load the gis data
  clear-all
  reset-ticks
  set GEOID-list []
  set ct-patient-num-list []
  set ct-patient-A-num-list []
  set ct-A-list []
  set senior-clinics-dataset gis:load-dataset "Data/SFSeniorHealth_Project.shp"
  set non-senior-clinics-dataset gis:load-dataset "Data/SFNOTSeniorHealth_Project.shp"
  set censusBlocks-dataset gis:load-dataset "Data/SF_BlockGrps_Elder_A_Project/SF_BlockGrps_Elder_A_Project.shp"
  ask patches[
    set Clinic-here? False
    set seniorClinic-here? False
    set preference -1
    set patient-A-num 0
  ]
  load-patch-data
end

to load-patch-data ; draw the map and apply the vector data to the raster in NetLogo for the socioeconomic data
  clear-drawing
  reset-ticks
  gis:set-world-envelope (gis:envelope-union-of;set the study area
    (gis:envelope-of senior-clinics-dataset)
    (gis:envelope-of non-senior-clinics-dataset)
    (gis:envelope-of censusBlocks-dataset)
  )

  foreach gis:feature-list-of censusBlocks-dataset[ ? ->
    ask patches gis:intersecting ? [
      set tract-id gis:property-value ? "GEOID"
    ]
  ]
  foreach gis:feature-list-of non-senior-clinics-dataset[ ? ->
    ask patches gis:intersecting ? [
      set Clinic-here? True
      set clinic-name gis:property-value ? "FACILITY_N"
      set preference 1
    ]
  ]
  foreach gis:feature-list-of senior-clinics-dataset[ ? ->
    ask patches gis:intersecting ? [
      set seniorClinic-here? True
      set Clinic-here? True
      set clinic-name gis:property-value ? "FACILITY_N"
      set preference 2
    ]
  ]

  ;sample: show sort-by [ [string1 string2] -> length string1 < length string2 ] ["Grumpy" "Doc" "Happy"] => ["Doc" "Happy" "Grumpy"]
  ;sample: loop [if not can-move? 1 [ stop ] fd 1]
  ifelse file-exists? "./Data/SF_CensusBlock_ex/censusblocks_attributes.txt"
  [
    file-open "./Data/SF_CensusBlock_ex/censusblocks_attributes.csv"
    while [not file-at-end?]
    [
      let line csv:from-row file-read-line
      let GEOID item 1 line
      set GEOID-list lput GEOID GEOID-list
;      show GEOID
      let M_F_ELDER item 9 line
      let ct-pov item 13 line
      let ct-disability item 14 line
      let ct-health_ins item 15 line
      let ct-edu item 17 line
      let ct-cancer item 19 line
      let ct-bpHigh item 20 line
      let ct-diabetes item 21 line


      ask patches with [tract-id = GEOID][
;        set ct-here? True
        ;attributes for agents
        set education ct-edu
        set poverty ct-pov
        set cancerValue ct-cancer
        set highBloodPressure ct-bpHigh
        set diabetesValue ct-diabetes
      ]
    ]
    foreach GEOID-list [ x ->
      set ct-patient-num-list lput 0 ct-patient-num-list
      set ct-patient-A-num-list lput 0 ct-patient-A-num-list
      set ct-A-list lput 0 ct-A-list
    ]
    print "set up patches with attributes completed!"
    file-close
  ]
  [user-message "There is no txt file for census blocks"]
  draw

;  ask patches [
;    if tract-id = 0 [set preference -1]
;  ]
end

to draw

  ask patches [set pcolor white]
  ;  mark Senior Clinics
  gis:set-drawing-color gray
  gis:draw censusBlocks-dataset  0.5

  gis:set-drawing-color green
  gis:draw senior-clinics-dataset 3
  gis:set-drawing-color red
  gis:draw non-senior-clinics-dataset 3

end

to reset-patients
  reset-ticks
  clear-drawing
  ask patients[die]
  draw
  set ct-patient-num-list []
  set ct-patient-num-list []
  set ct-patient-A-num-list []
  set ct-A-list []
  ask patches [
    set patient-A-num 0
  ]
  foreach GEOID-list [ x ->
    set ct-patient-num-list lput 0 ct-patient-num-list
    set ct-patient-A-num-list lput 0 ct-patient-A-num-list
    set ct-A-list lput 0 ct-A-list
  ]
  print "reset patients"
end

to make-patients
  set senior-pops 134981
  set num-patients round(senior-pops * patient-ratio / 100); 80989
;  let num-patients-variation (random-float 0.01 - 0.02)
  set num-patients-today round(num-patients * 0.019);https://www.ncbi.nlm.nih.gov/books/NBK215400/ => Mean number of senior patients per day = (7 visits per year) / (365 days per year) = 0.019 senior patients per day (Note that these estimates are based on several assumptions, such as seniors in San Francisco having similar healthcare utilization patterns as the national average. )
  print num-patients-today
  repeat num-patients-today
  [
    ask one-of patches with [ tract-id > 0] [  sprout-patients 1  ]
  ]
  ; calculate how many patient in one census tract?
  ask patients [
    set shape "person"
    set size 2
    set move? False
    let patch-where-patient-born patch-here
    ask patch-where-patient-born[
      set num-patients-in-patch (num-patients-in-patch + 1)
    ]
  ]
;  let selected-patch patch 0 1
;  ask selected-patch[
;    set ct-num-patients count turtles-here with [ shape = "person" ]
;  ]
;  print ct-num-patients
  ;  let len-GEOID length GEOID-list
  ;  foreach range len-GEOID [ i ->
  ;    let temp-geoid (item i GEOID-list)
  ;    let ct-patches patches with [tract-id = temp-geoid]
  ;    ask ct-patches[
  ;      set temp-ct-num-patients count turtles-here with [shape = "person"]
  ;    ]
  ;    set ct-patient-num-list replace-item i ct-patient-num-list (temp-ct-num-patients + (item i ct-patient-num-list)) ;每个ct的总patient数在随时间增加
  ;    set temp-ct-num-patients 0
  ;  ]
;  create-patients num-patients-today[
;    setxy random-xcor random-ycor
;  ]
  ask patients [
    set patient-arrive-time ((random 35) + 1 );patients arrive time between 8am - 5pm, 1 tick = 15min, 8am = tick 0, 5pm = tick 36
    set patient-duration round(((random 4) + 1) * (duration + 1)) ; duration between 15min - 2h
    set p-edu [education] of patch-here
    set p-pov [poverty] of patch-here
    set p-cancer [cancerValue] of patch-here
    set p-bpHigh [highBloodPressure] of patch-here
    set p-diabetes [diabetesValue] of patch-here
  ]
;  ask patients[
;    set patient-A? False
;  ]
  print "set up patients completed!"
end

to make-healthcare-facilities
  ask patches with [Clinic-here? = True] [
;  sprout-healthcare-facilities 1 [
;    set h-num-physicians (8 + (random 8 - 4))
;    set h-positions h-num-physicians
;  ]
    set h-num-physicians (8 + (random 8 - 4))
    set h-positions h-num-physicians

  ]
  print "set up healthcare facilities completed!"
end

to patients-move
  ask patients [
    if ticks = patient-arrive-time [
      let best-patch max-one-of patches in-radius distance-tolerance [preference]
;      print best-patch
      ifelse [preference] of best-patch = -1 [
        die
        print "no clinics"
      ][
        ifelse [h-positions] of patch-here < 0[
          die
        ][
          ifelse (36 - patient-arrive-time) < patient-duration [
            die
          ][
            ask patch-here[
              set patient-A-num patient-A-num + 1 ; if patient move, the original patch will add 1 to patient-A-num
            ]
;            pen-down
            set move? True
            move-to best-patch
            let clinic-patch patch-here
            ask clinic-patch [
              set h-positions (h-positions - 1)
            ]
          ]
        ]
      ]
    ]
  ]
end

to calculate-accessibility
;  foreach GEOID-list [ x ->
;    let ct-patches patches with [tract-id = x]
;    let ct-num-patients-A sum [patient-A-num] of ct-patches
;    set ct-patient-A-num-list lput ct-num-patients-A ct-patient-A-num-list
;  ]
  set ct-patient-A-num-list lput 0 ct-patient-A-num-list
  set ct-patient-num-list lput 0 ct-patient-num-list
  let len-GEOID length GEOID-list
  ;sample:
;  foreach n-values given-number [ i ->
;  ;; code to execute in each iteration of the loop
;  show i
  ;；；；；；；；；；；；；；；；；；；；；；；；；；；；；；；；；；；；；；；；；；；；；；；；；；；；；改
  foreach range len-GEOID [i ->
    let temp-geoid (item i GEOID-list)
    let ct-patches patches with [tract-id = temp-geoid]
    let ct-num-patients-A sum [patient-A-num] of ct-patches
    ; sample (replace list): let updated-list replace-item 2 my-list (item 2 my-list + 1)
    set ct-patient-A-num-list replace-item i ct-patient-A-num-list ct-num-patients-A

    let ct-num-patients sum [num-patients-in-patch] of ct-patches
    set ct-patient-num-list replace-item i ct-patient-num-list ct-num-patients

    ifelse item i ct-patient-num-list = 0 [
      set res 0
    ][
      set res ((item i ct-patient-A-num-list) / (item i ct-patient-num-list))
    ]
    set ct-A-list replace-item i ct-A-list res
;    print res
;    let ct-patches patches with [tract-id = item i GEOID-list]
    ifelse color-map = true [ ;Switch button
      ask patients [
        set hidden? True
      ]
      ask ct-patches [
        set pcolor palette:scale-gradient palette:scheme-colors "Divergent" "Spectral" 8 (item i ct-A-list) (max ct-A-list) (min ct-A-list);ct-A-list越小，颜色越蓝，越无法到达 ;palette:scale-scheme "Sequential" "Reds" 9
      ]
    ][
      ask patients [set hidden? False]
      clear-drawing
      draw
    ]
    set res 0;；；；；；；；；；；；；；；；；；；；；；；；；；；；；；；；；；；；；；；；；；；；；；
  ]
  print "accessiblility map is completed"

end

to accessibility-histogram
  set-plot-x-range 0 1
  set-plot-y-range 0 200
  set-histogram-num-bars 20
end

to go
  tick
  patients-move
  ask patients [
    if move? = True [
      set patient-duration (patient-duration - 1)
      if patient-duration < 0 [
        die
        let clinic-patch patch-here
        ask clinic-patch [
          set h-positions h-positions + 1
        ]
      ]
    ]
  ]
  if ticks = 36 [
    reset-ticks
    make-patients
    make-healthcare-facilities
;    patients-move
;    calculate-accessibility
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
0
10
810
821
-1
-1
2.0
1
10
1
1
1
0
1
1
1
-200
200
-200
200
1
1
1
ticks
30.0

BUTTON
1009
15
1075
48
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
824
15
996
48
patient-ratio
patient-ratio
0
60
60.0
1
1
NIL
HORIZONTAL

BUTTON
825
61
945
94
NIL
make-patients
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1082
63
1275
96
NIL
make-healthcare-facilities
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
824
151
887
185
NIL
go\n
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
1002
193
1125
226
color-map
color-map
0
1
-1000

BUTTON
954
62
1073
95
NIL
reset-patients
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
896
152
959
185
NIL
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
824
193
991
226
NIL
calculate-accessibility
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
822
239
1022
389
accessibility-distribution
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" "accessibility-histogram"
PENS
"pen-0" 1.0 1 -7500403 true "" "histogram ct-A-list"

SLIDER
821
397
1041
430
duration
duration
-0.5
0.50
-0.5
0.01
1
NIL
HORIZONTAL

SLIDER
824
109
996
142
distance-tolerance
distance-tolerance
5
30
30.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
