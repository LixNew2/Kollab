shader_type canvas_item;

uniform int kernel_size: hint_range(1, 25) = 5;
uniform sampler2D screen_tex : hint_screen_texture;

float gaussian(float x, float sigma) {
    return exp(-(x * x) / (2.0 * sigma * sigma)) / (sqrt(2.0 * 3.14159265359) * sigma);
}

vec4 gaussian_blur(sampler2D tex, vec2 fragCoord, vec2 pixelSize, int kernelSize) {
    vec4 color = vec4(0.0);

    float sigma = float(kernelSize) / 3.0;
    float totalWeight = 0.0;

    for (int i = -kernelSize; i <= kernelSize; i++) {
        for (int j = -kernelSize; j <= kernelSize; j++) {
            vec2 offset = vec2(float(i), float(j));
            color += texture(tex, fragCoord + offset * pixelSize) * gaussian(length(offset), sigma);
            totalWeight += gaussian(length(offset), sigma);
        }
    }

    return color / totalWeight;
}

void fragment() {
    COLOR = gaussian_blur(screen_tex, SCREEN_UV, SCREEN_PIXEL_SIZE, kernel_size);
}