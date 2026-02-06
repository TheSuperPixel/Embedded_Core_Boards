/*
//-----------------------------------------
//CMOS Camera interface and data output simulation
wire			cmos_xclk;
wire			cmos_pclk;				//25MHz when rgb output, 12.5MHz when raw output
wire			cmos_vsync;				//L: vaild, H: invalid
wire			cmos_href;				//H: vaild, L: invalid
wire	[7:0]	cmos_data;				//8 bits cmos data input
Video_Image_Simulate_CMOS	
#(
	.CMOS_VSYNC_VALID	(1'b0),     //OmniVison = 0; Micron = 1
	.IMG_HDISP			(10'd16),	//(10'd640),	//640*480
	.IMG_VDISP			(10'd4)		//(10'd480)
)
u_Video_Image_Simulate_CMOS
(
	//global reset
	.rst_n				(sys_rst_n),	
	
	//CMOS Camera interface and data output simulation
	.cmos_xclk			(cmos_xclk),		//25MHz cmos clock
	.cmos_pclk			(cmos_pclk),		//25MHz when rgb output, 12.5MHz when raw output
	.cmos_vsync			(cmos_vsync),		//L: vaild, H: invalid
	.cmos_href			(cmos_href),		//H: vaild, L: invalid
	.cmos_data			(cmos_data)			//8 bits cmos data input
);
***************************************************************************/

`timescale 1ns/1ns
module	Video_Image_Simulate_CMOS
#(
	parameter			CMOS_VSYNC_VALID	=	1'b1,		//H : Data Valid; L : Frame Sync(Set it by register)
	parameter		IMG_HDISP 			= 	11'd800,	//640*480
	parameter		IMG_VDISP 			= 	11'd480
)
(
	//global reset
	input				rst_n,		
	
	//CMOS Camera interface and data output simulation
	input				cmos_xclk,			//cmos driver clock
	output				cmos_pclk,			//25MHz when rgb output, 12.5MHz when raw output
	output				cmos_vsync,			//L: vaild, H: invalid
	output	reg			cmos_href,			//H: vaild, L: invalid
	output	reg	[7:0]	cmos_data			//8 bits cmos data input
);
wire	clk		=	cmos_xclk;
// wire	rst_n 	= 	1'b1;

//------------------------------------------
//generate cmos timing

//localparam H_SYNC = 11'd128;
//localparam H_BACK = 11'd88;
//localparam H_DISP = IMG_HDISP;	//11'd640
//localparam H_FRONT = 11'd40;
//localparam H_TOTAL = H_SYNC + H_BACK + H_DISP + H_FRONT;	//10'd784

//localparam V_SYNC = 11'd2;
//localparam V_BACK = 11'd33;
//localparam V_DISP = IMG_VDISP;	//11'd480
//localparam V_FRONT = 11'd10;
//localparam V_TOTAL = V_SYNC + V_BACK + V_DISP + V_FRONT;	//10'd510

//Just for simulation
 localparam H_SYNC = 11'd5;		
 localparam H_BACK = 11'd5;		
 localparam H_DISP = IMG_HDISP;	
 localparam H_FRONT = 11'd5;		
 localparam H_TOTAL = H_SYNC + H_BACK + H_DISP + H_FRONT;	//10'd784

 localparam V_SYNC = 11'd1;		
 localparam V_BACK = 11'd0;		
 localparam V_DISP = IMG_VDISP;	
 localparam V_FRONT = 11'd1;		
 localparam V_TOTAL = V_SYNC + V_BACK + V_DISP + V_FRONT;	//10'd510

//----------------------------------
////25MHz when rgb output, 12.5MHz when raw output
reg		pixel_cnt;
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		pixel_cnt <= 0;
	else 
		pixel_cnt <= pixel_cnt + 1'b1;
end
wire	pixel_flag	=	1'b1;
assign	cmos_pclk	= 	~clk;
											
//---------------------------------------------
//Horizontal counter
reg	[10:0]	hcnt;
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		hcnt <= 11'd0;
	else if(pixel_flag)
		hcnt <= (hcnt < H_TOTAL - 1'b1) ? hcnt + 1'b1 : 11'd0;
	else
		hcnt <= hcnt;
end

//---------------------------------------------
//Vertical counter
reg	[10:0]	vcnt;
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		vcnt <= 11'd0;		
	else if(pixel_flag)
		begin
		if(hcnt == H_TOTAL - 1'b1)
			vcnt <= (vcnt < V_TOTAL - 1'b1) ? vcnt + 1'b1 : 11'd0;
		else
			vcnt <= vcnt;
		end
	else
		vcnt <= vcnt;
end

//---------------------------------------------
//Image data vsync valid signal
reg	cmos_vsync_r;
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		cmos_vsync_r <= 1'b0;			//H: Vaild, L: inVaild
	else if(pixel_flag)
		begin
		if(vcnt <= V_SYNC - 1'b1)
			cmos_vsync_r <= 1'b0; 	//H: Vaild, L: inVaild
		else
			cmos_vsync_r <= 1'b1; 	//H: Vaild, L: inVaild
		end
	else
		cmos_vsync_r <= cmos_vsync_r;
end
assign	cmos_vsync	=	(CMOS_VSYNC_VALID	== 1'b0) ? ~cmos_vsync_r :	cmos_vsync_r;

//---------------------------------------------
//Image data href vaild  signal
wire	frame_valid_ahead = ((vcnt >= V_SYNC + V_BACK  && vcnt < V_SYNC + V_BACK + V_DISP &&
						hcnt >= H_SYNC + H_BACK  && hcnt < H_SYNC + H_BACK + H_DISP)) 
						? 1'b1 : 1'b0;
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		cmos_href <= 0;
	else if(pixel_flag) 
		begin
		if(frame_valid_ahead)
			cmos_href <= 1;
		else
			cmos_href <= 0;
		end
	else
		cmos_href <= cmos_href;
end

//---------------------------------------------
//CMOS Camera data output
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		cmos_data <= 16'd0;
	else if(pixel_flag)
		begin
		if(frame_valid_ahead)
			cmos_data <= hcnt[7:0] - (8'd10 - 8'd1);
		else
			cmos_data <= 0;
		end
	else
		cmos_data <= cmos_data;
end

endmodule