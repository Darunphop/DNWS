__kernel void imagingTest(__read_only  image2d_t srcImg,
                       __write_only image2d_t dstImg)
{
  const sampler_t smp = CLK_NORMALIZED_COORDS_FALSE | //Natural coordinates
    CLK_ADDRESS_CLAMP_TO_EDGE | //Clamp to zeros
    CLK_FILTER_LINEAR;

  float gx = 0;
  float gy = 0;

  int2 refIndex[9] = {
    (-1,-1), (-1, 0), (-1, 1),
    ( 0,-1), ( 0, 0), ( 0, 1),
    ( 1,-1), ( 1, 0), ( 1, 1)};

  float gxOperand[9] = {
    1, 0, -1,
    2, 0, -2,
    1, 0, -1};
  float gyOperand[9] = {
     1,  2,  1,
     0,  0,  0,
    -1, -2, -1};

  for(int i=0; i<9; i++){
    int j = 9 - i - 1;
    int2 refCoord = (int2)(get_global_id(0) + refIndex[i].x, get_global_id(1) + refIndex[i].y);
    uint4 bgra = read_imageui(srcImg, smp, refCoord); //The byte order is BGRA
    float4 bgrafloat = convert_float4(bgra) / 255.0f; //Convert to normalized [0..1] float
    //Convert RGB to luminance (make the image grayscale).
    float luminance =  sqrt(0.241f * bgrafloat.z * bgrafloat.z + 0.691f * 
                        bgrafloat.y * bgrafloat.y + 0.068f * bgrafloat.x * bgrafloat.x);
    gx += luminance * gxOperand[j];
    gy += luminance * gyOperand[j];
  }
  float g = sqrt((gx*gx) + (gy*gy));

  int2 coord = (int2)(get_global_id(0), get_global_id(1));
  uint4 newBgra = (uint4)((uint)(g*255.0), (uint)(g*255.0), (uint)(g*255.0),255);
  write_imageui(dstImg, coord, newBgra);
}