// Donkere buitencontour van 1 px om de echo (Technical Artist, #226, risico R2;
// bible §1 "lijnwerk": de echo in zijn eigenaarskleur, daarbuiten 1 px bijna-zwart).
//
// Voor een sprite met alfa: een pixel buiten het silhouet (alfa 0) met een buur
// erin (boven, onder, links of rechts, zoals `outer_of` in genereer_r5.py) wordt
// `contour_kleur`. Het silhouet is alfa > 0: de holle pixels van de echo hebben
// alfa 1/255 en worden hier helemaal doorzichtig, zodat de contour buiten de
// figuur ligt en niet in het gat.
//
// Eisen aan de sprite: filter Nearest, 1 px transparante rand rond elk frame
// (ook in een atlas), geen mipmaps. De uniform heeft geen kleur-hint: er gebeurt
// geen sRGB-omzetting, de waarde komt exact in de framebuffer (2D zonder HDR).
// De contour verandert niet met de toestand (grijs, half, kleur) en niet met
// `modulate` (de figuur zelf wel): hij blijft in elke toestand staan.
shader_type canvas_item;

uniform vec4 contour_kleur = vec4(0.02745, 0.01961, 0.04706, 1.0); // #07050c

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (c.a > 0.0) {
		// In het silhouet: wat de sprite tekent, of niets in het gat (alfa 1/255).
		COLOR = c.a * 255.0 < 1.5 ? vec4(0.0) : COLOR;
	} else {
		vec2 px = TEXTURE_PIXEL_SIZE;
		float n = texture(TEXTURE, UV + vec2(px.x, 0.0)).a + texture(TEXTURE, UV - vec2(px.x, 0.0)).a
			+ texture(TEXTURE, UV + vec2(0.0, px.y)).a + texture(TEXTURE, UV - vec2(0.0, px.y)).a;
		COLOR = n > 0.0 ? contour_kleur : vec4(0.0);
	}
}
