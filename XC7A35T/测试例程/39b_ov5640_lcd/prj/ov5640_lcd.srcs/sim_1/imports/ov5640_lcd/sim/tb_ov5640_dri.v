`timescale 1ns/1ns

module tb_ov5640_dri;

//reg define
reg           clk_50m;
reg           rst_n;
reg    [12:0] cmos_h_pixel;
reg    [12:0] cmos_v_pixel;
reg    [12:0] total_h_pixel;
reg    [12:0] total_v_pixel;
reg    [12:0] y_addr_st;
reg    [12:0] y_addr_end;
reg           capture_start;

//wire define
wire          cam_init_done;                                                        
wire          cmos_frame_vsync;
wire          cmos_frame_href;
wire          cmos_frame_valid;
wire   [15:0] cmos_frame_data;
//CMOS Camera interface and data output simulation
wire          cmos_pclk;				//24MHz CMOS Pixel clock input
wire          cmos_vsync;				//L: vaild, H: invalid
wire          cmos_href;				//H: vaild, L: invalid
wire    [7:0] cmos_data;				//8 bits cmos data input
wire          cam_rst_n;
wire          cam_pwdn ;
wire          cam_scl;
wire          cam_sda;

//**************************************************************************//
// Reset Generation
//**************************************************************************//
initial begin
  rst_n = 1'b0;
  capture_start = 1'b1;
  cmos_h_pixel  = 13'd0; 
  cmos_v_pixel  = 13'd0; 
  total_h_pixel = 13'd0;
  total_v_pixel = 13'd0;
  y_addr_st     = 13'd0;    
  y_addr_end    = 13'd0;   
  #200
  cmos_h_pixel  = 13'd800;  
  cmos_v_pixel  = 13'd480;  
  total_h_pixel = 13'd1800;  
  total_v_pixel = 13'd1000;  
  y_addr_st     = 13'd187;  
  y_addr_end    = 13'd1763;  
  rst_n = 1'b1;
end

//**************************************************************************//
// Clock Generation
//**************************************************************************//
initial
    clk_50m = 1'b0;
always
    clk_50m = #10 ~clk_50m;

//Generate 48MHz driver clock
reg    clk; 
wire   clk_cmos = clk;        //48MHz
initial    
    clk = 1'b0;
always       
    clk = #11 ~clk;
    
//===========================================================================
//                                 FPGA Memory Controller
//===========================================================================
ov5640_dri u_ov5640_dri(
    .clk               (clk_50m),
    .rst_n             (rst_n),

    .cam_pclk          (cmos_pclk),
    .cam_vsync         (cmos_vsync),
    .cam_href          (cmos_href),
    .cam_data          (cmos_data),
    .cam_rst_n         (cam_rst_n),
    .cam_pwdn          (cam_pwdn),
    .cam_scl           (cam_scl),
    .cam_sda           (cam_sda),
    
    .cam_init_done     (cam_init_done),
    .capture_start     (capture_start),
    .cmos_h_pixel      (cmos_h_pixel),
    .cmos_v_pixel      (cmos_v_pixel),
    .total_h_pixel     (total_h_pixel),
    .total_v_pixel     (total_v_pixel),
    .y_addr_st         (y_addr_st ),
    .y_addr_end        (y_addr_end),
    .cmos_frame_vsync  (cmos_frame_vsync),
    .cmos_frame_href   (cmos_frame_href),
    .cmos_frame_valid  (cmos_frame_valid),
    .cmos_frame_data   (cmos_frame_data)
);

//**************************************************************************//
//  Models instantiations
//**************************************************************************//

Video_Image_Simulate_CMOS  
#(
    .CMOS_VSYNC_VALID    (1'b1),     //VSYNC = 1
    .IMG_HDISP           (10'd32),    //(10'd640),    //640*480
    .IMG_VDISP           (10'd4)        //(10'd480)
)
u_Video_Image_Simulate_CMOS
(
    //global reset
    .rst_n                (rst_n & cam_init_done),    
    
    //CMOS Camera interface and data output simulation
    .cmos_xclk            (clk_cmos),          //48MHz cmos clock
    .cmos_pclk            (cmos_pclk ),        //48MHz when rgb output
    .cmos_vsync           (cmos_vsync),        //L: vaild, H: invalid
    .cmos_href            (cmos_href ),        //H: vaild, L: invalid
    .cmos_data            (cmos_data )         //8 bits cmos data input
);

endmodule