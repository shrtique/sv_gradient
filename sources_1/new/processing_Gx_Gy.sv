`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////


module processing_Gx_Gy #(

  parameter DATA_WIDTH  = 8,
  parameter KERNEL_SIZE = 5

)(	

  input  logic                  i_clk,
  input  logic                  i_aresetn,

  input  logic [DATA_WIDTH-1:0] i_image_kernel_buffer [0:KERNEL_SIZE-1] [0:KERNEL_SIZE-1],
  input  logic                  i_data_valid,
  input  logic                  i_start_of_frame,

  output logic [DATA_WIDTH-1:0] i_pixel,
  output logic                  o_data_valid,
  output logic                  o_start_of_frame	

);

//DESCRIPTION:
//////////////////////////////////////////////////////////////////////////////////
//Lets try to use Prewitt kernel 5x5
//
//      -2, -1, 0, 1, 2          2,  2,  2,  2,  2
//      -2, -1, 0, 1, 2          1,  1,  1,  1,  1
// Gx = -2, -1, 0, 1, 2    Gy =  0,  0,  0,  0,  0 
//      -2, -1, 0, 1, 2         -1, -1, -1, -1, -1
//      -2, -1, 0, 1, 2         -2, -2, -2, -2, -2
//
//////////////////////////////////////////////////////////////////////////////////

//SUMS Gx_cols

logic signed [DATA_WIDTH+4:0] Gx_col [0:3]; // one col with zeros we miss

//
always_ff @( posedge i_clk, negedge i_aresetn ) begin
  if ( ~i_aresetn ) begin
    Gx_col <= '{default: 'b0};
  end else begin
    Gx_col[0] <= - ( ( i_image_kernel_buffer[4][4] + i_image_kernel_buffer[3][4] + i_image_kernel_buffer[2][4] + i_image_kernel_buffer[1][4] + i_image_kernel_buffer[0][4] ) << 1 );
    Gx_col[1] <= -   ( i_image_kernel_buffer[4][3] + i_image_kernel_buffer[3][3] + i_image_kernel_buffer[2][3] + i_image_kernel_buffer[1][3] + i_image_kernel_buffer[0][3] );
    Gx_col[2] <=     ( i_image_kernel_buffer[4][1] + i_image_kernel_buffer[3][1] + i_image_kernel_buffer[2][1] + i_image_kernel_buffer[1][1] + i_image_kernel_buffer[0][1] );
    Gx_col[3] <=   ( ( i_image_kernel_buffer[4][0] + i_image_kernel_buffer[3][0] + i_image_kernel_buffer[2][0] + i_image_kernel_buffer[1][0] + i_image_kernel_buffer[0][0] ) << 1 );  
  end 
end 


//SUMS Gy_rows
logic signed [DATA_WIDTH+4:0] Gy_row [0:3]; // one row with zeros we miss

//
always_ff @( posedge i_clk, negedge i_aresetn ) begin
  if ( ~i_aresetn ) begin
    Gy_row <= '{default: 'b0};
  end else begin
    Gy_row[0] <=   ( ( i_image_kernel_buffer[4][4] + i_image_kernel_buffer[4][3] + i_image_kernel_buffer[4][2] + i_image_kernel_buffer[4][1] + i_image_kernel_buffer[4][0] ) << 1 );
    Gy_row[1] <=     ( i_image_kernel_buffer[3][4] + i_image_kernel_buffer[3][3] + i_image_kernel_buffer[3][2] + i_image_kernel_buffer[3][1] + i_image_kernel_buffer[3][0] );
    Gy_row[2] <= -   ( i_image_kernel_buffer[1][4] + i_image_kernel_buffer[1][3] + i_image_kernel_buffer[1][2] + i_image_kernel_buffer[1][1] + i_image_kernel_buffer[1][0] );
    Gy_row[3] <= - ( ( i_image_kernel_buffer[0][4] + i_image_kernel_buffer[0][3] + i_image_kernel_buffer[0][2] + i_image_kernel_buffer[0][1] + i_image_kernel_buffer[0][0] ) << 1 );  
  end 
end 


//SUMS Gx, SUMS Gy
logic signed [DATA_WIDTH+4:0] Gx;
logic signed [DATA_WIDTH+4:0] Gy;

//
always_ff @( posedge i_clk, negedge i_aresetn ) begin
  if ( ~i_aresetn ) begin
    Gx <= '{default: 'b0};
    Gy <= '{default: 'b0};
  end else begin
    Gx <= Gx_col[0] + Gx_col[1] + Gx_col[2] + Gx_col[3];
    Gy <= Gy_row[0] + Gy_row[1] + Gy_row[2] + Gy_row[3];
  end 
end 
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
endmodule
