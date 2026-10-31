// Skia runtime effects require constant indices into uniform arrays.
// Keep the same 16-shape/6-float layout and SDF as the native backend.
float getShapeSDFFromArray(int index, vec2 p) {
    if (index == 0) return getShapeSDF(uShapeData[0], p,
        vec2(uShapeData[1], uShapeData[2]),
        vec2(uShapeData[3], uShapeData[4]), uShapeData[5]);
    if (index == 1) return getShapeSDF(uShapeData[6], p,
        vec2(uShapeData[7], uShapeData[8]),
        vec2(uShapeData[9], uShapeData[10]), uShapeData[11]);
    if (index == 2) return getShapeSDF(uShapeData[12], p,
        vec2(uShapeData[13], uShapeData[14]),
        vec2(uShapeData[15], uShapeData[16]), uShapeData[17]);
    if (index == 3) return getShapeSDF(uShapeData[18], p,
        vec2(uShapeData[19], uShapeData[20]),
        vec2(uShapeData[21], uShapeData[22]), uShapeData[23]);
    if (index == 4) return getShapeSDF(uShapeData[24], p,
        vec2(uShapeData[25], uShapeData[26]),
        vec2(uShapeData[27], uShapeData[28]), uShapeData[29]);
    if (index == 5) return getShapeSDF(uShapeData[30], p,
        vec2(uShapeData[31], uShapeData[32]),
        vec2(uShapeData[33], uShapeData[34]), uShapeData[35]);
    if (index == 6) return getShapeSDF(uShapeData[36], p,
        vec2(uShapeData[37], uShapeData[38]),
        vec2(uShapeData[39], uShapeData[40]), uShapeData[41]);
    if (index == 7) return getShapeSDF(uShapeData[42], p,
        vec2(uShapeData[43], uShapeData[44]),
        vec2(uShapeData[45], uShapeData[46]), uShapeData[47]);
    if (index == 8) return getShapeSDF(uShapeData[48], p,
        vec2(uShapeData[49], uShapeData[50]),
        vec2(uShapeData[51], uShapeData[52]), uShapeData[53]);
    if (index == 9) return getShapeSDF(uShapeData[54], p,
        vec2(uShapeData[55], uShapeData[56]),
        vec2(uShapeData[57], uShapeData[58]), uShapeData[59]);
    if (index == 10) return getShapeSDF(uShapeData[60], p,
        vec2(uShapeData[61], uShapeData[62]),
        vec2(uShapeData[63], uShapeData[64]), uShapeData[65]);
    if (index == 11) return getShapeSDF(uShapeData[66], p,
        vec2(uShapeData[67], uShapeData[68]),
        vec2(uShapeData[69], uShapeData[70]), uShapeData[71]);
    if (index == 12) return getShapeSDF(uShapeData[72], p,
        vec2(uShapeData[73], uShapeData[74]),
        vec2(uShapeData[75], uShapeData[76]), uShapeData[77]);
    if (index == 13) return getShapeSDF(uShapeData[78], p,
        vec2(uShapeData[79], uShapeData[80]),
        vec2(uShapeData[81], uShapeData[82]), uShapeData[83]);
    if (index == 14) return getShapeSDF(uShapeData[84], p,
        vec2(uShapeData[85], uShapeData[86]),
        vec2(uShapeData[87], uShapeData[88]), uShapeData[89]);
    if (index == 15) return getShapeSDF(uShapeData[90], p,
        vec2(uShapeData[91], uShapeData[92]),
        vec2(uShapeData[93], uShapeData[94]), uShapeData[95]);
    return 1e9;
}
