`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 31.01.2019 16:13:55
// Design Name: 
// Module Name: tb_top_module_Gx_Gy
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_top_module_Gx_Gy(

    );

localparam DATA_WIDTH  = 8;
localparam WIDTH       = 800;
localparam HEIGHT      = 400;
localparam KERNEL_SIZE = 5;


//signals
logic clk;
logic aresetn;

logic [DATA_WIDTH-1:0]   tdata;
logic                    tvalid;
logic                    tuser;
logic                    tlast;  


tb_video_stream #(
  .N                ( DATA_WIDTH ),
  .width            ( WIDTH ),
  .height           ( HEIGHT ) 

) data_generator (
  .sys_clk          ( clk ),
  .sys_aresetn      ( aresetn ),

  .reg_video_tdata  ( tdata ),
  .reg_video_tvalid ( tvalid ),
  .reg_video_tlast  ( tlast ),
  .reg_video_tuser  ( tuser )
);
//
//



//signals
logic [31:0]           tdata_gxgy;
logic                  tvalid_gxgy;
logic                  tuser_gxgy;
logic                  tlast_gxgy; 
// 
top_module_Gx_Gy #(

  .DATA_WIDTH    ( DATA_WIDTH  ),
  //.IMG_WIDTH     ( WIDTH       ),
  //.IMG_HEIGHT    ( HEIGHT      ),
  .KERNEL_SIZE   ( KERNEL_SIZE )

) UUT (

  .i_clk         ( clk           ),
  .i_aresetn     ( aresetn       ),

  .WIDTH         ( WIDTH         ),
  .HEIGHT        ( HEIGHT        ),

  .s_axis_tdata  ( tdata         ),
  .s_axis_tvalid ( tvalid        ),
  .s_axis_tuser  ( tuser         ),
  .s_axis_tlast  ( tlast         ),
  .s_axis_tready (               ),

  .m_axis_tdata  ( tdata_gxgy    ),
  .m_axis_tvalid ( tvalid_gxgy   ),
  .m_axis_tuser  ( tuser_gxgy    ),
  .m_axis_tlast  ( tlast_gxgy    )

);
//
//


tb_savefile_axis_data #(

  .N      ( 32         ),
  .height ( HEIGHT     ),
  .width  ( WIDTH      )

) save_image_to_file (
  .i_sys_clk          ( clk         ),
  .i_sys_aresetn      ( aresetn     ),

  .i_reg_video_tdata  ( tdata_gxgy  ),
  .i_reg_video_tvalid ( tvalid_gxgy ),
  .i_reg_video_tuser  ( tuser_gxgy  ),
  .i_reg_video_tlast  ( tlast_gxgy  )
  );


endmodule
