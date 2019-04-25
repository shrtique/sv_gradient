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

  output logic [31:0]           o_Gx_Gy_vector,
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

//////////////////////////////////////////////////////////////////////////////////
// Here we add input stage for image data, cause i_image_kernel_buffer has relatively large fanout for high speed design
// Let's try

logic [DATA_WIDTH-1:0] image_kernel_buffer [0:KERNEL_SIZE-1] [0:KERNEL_SIZE-1];

always_ff @( posedge i_clk, negedge i_aresetn ) begin 
  if ( ~i_aresetn ) begin
    image_kernel_buffer <= '{default: '0};
  end else begin
    image_kernel_buffer <= i_image_kernel_buffer;
  end
end
//////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////////////
//SUMS Gx_cols

logic signed [DATA_WIDTH+4:0] Gx_col [0:3]; // one col with zeros we miss

//
always_ff @( posedge i_clk, negedge i_aresetn ) begin
  if ( ~i_aresetn ) begin
    Gx_col <= '{default: 'b0};
  end else begin
    Gx_col[0] <= - ( ( image_kernel_buffer[0][0] + image_kernel_buffer[1][0] + image_kernel_buffer[2][0] + image_kernel_buffer[3][0] + image_kernel_buffer[4][0] ) << 1 );
    Gx_col[1] <= -   ( image_kernel_buffer[0][1] + image_kernel_buffer[1][1] + image_kernel_buffer[2][1] + image_kernel_buffer[3][1] + image_kernel_buffer[4][1] );
    Gx_col[2] <=     ( image_kernel_buffer[0][3] + image_kernel_buffer[1][3] + image_kernel_buffer[2][3] + image_kernel_buffer[3][3] + image_kernel_buffer[4][3] );
    Gx_col[3] <=   ( ( image_kernel_buffer[0][4] + image_kernel_buffer[1][4] + image_kernel_buffer[2][4] + image_kernel_buffer[3][4] + image_kernel_buffer[4][4] ) << 1 ); 
  end 
end 

//reg input data once again, for pipelining calculations of Gx and Gy
logic [DATA_WIDTH-1:0] image_kernel_buffer_reg [0:KERNEL_SIZE-1] [0:KERNEL_SIZE-1];

always_ff @( posedge i_clk, negedge i_aresetn ) begin 
  if ( ~i_aresetn ) begin
    image_kernel_buffer_reg <= '{default: '0};
  end else begin
    image_kernel_buffer_reg <= image_kernel_buffer;
  end
end
//////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////////////
//SUMS Gy_rows
logic signed [DATA_WIDTH+4:0] Gy_row [0:3]; // one row with zeros we miss

//
always_ff @( posedge i_clk, negedge i_aresetn ) begin
  if ( ~i_aresetn ) begin
    Gy_row <= '{default: 'b0};
  end else begin
    Gy_row[0] <=   ( ( image_kernel_buffer_reg[0][0] + image_kernel_buffer_reg[0][1] + image_kernel_buffer_reg[0][2] + image_kernel_buffer_reg[0][3] + image_kernel_buffer_reg[0][4] ) << 1 );
    Gy_row[1] <=     ( image_kernel_buffer_reg[1][0] + image_kernel_buffer_reg[1][1] + image_kernel_buffer_reg[1][2] + image_kernel_buffer_reg[1][3] + image_kernel_buffer_reg[1][4] );
    Gy_row[2] <= -   ( image_kernel_buffer_reg[3][0] + image_kernel_buffer_reg[3][1] + image_kernel_buffer_reg[3][2] + image_kernel_buffer_reg[3][3] + image_kernel_buffer_reg[3][4] );
    Gy_row[3] <= - ( ( image_kernel_buffer_reg[4][0] + image_kernel_buffer_reg[4][1] + image_kernel_buffer_reg[4][2] + image_kernel_buffer_reg[4][3] + image_kernel_buffer_reg[4][4] ) << 1 );
  end 
end 


logic signed [DATA_WIDTH+4:0] Gx_col_reg [0:3];

always_ff @( posedge i_clk, negedge i_aresetn ) begin 
  if ( ~i_aresetn ) begin
    Gx_col_reg <= '{default: '0};
  end else begin
    Gx_col_reg <= Gx_col;
  end
end
//////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////////////
//SUMS Gx, SUMS Gy
logic signed [DATA_WIDTH+4:0] Gx;
logic signed [DATA_WIDTH+4:0] Gy;

//
always_ff @( posedge i_clk, negedge i_aresetn ) begin
  if ( ~i_aresetn ) begin
    Gx <= '{default: 'b0};
    Gy <= '{default: 'b0};
  end else begin
    Gx <= Gx_col_reg[0] + Gx_col_reg[1] + Gx_col_reg[2] + Gx_col_reg[3];
    Gy <= Gy_row[0] + Gy_row[1] + Gy_row[2] + Gy_row[3];
  end 
end
//////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////
//
always_ff @( posedge i_clk, negedge i_aresetn ) begin
  if ( ~i_aresetn ) begin
    o_Gx_Gy_vector <= '{default: 'b0};
  end else begin
    o_Gx_Gy_vector [15:0]  <= Gx;
    o_Gx_Gy_vector [31:16] <= Gy;
  end 
end
//////////////////////////////////////////////////////////////////////////////////


//delay sof and valid to sync with next module (delay = 5 clk ticks, same as delay for Gx Gy processing)
//
//SIGNALS
logic delay_buffer_valid[0:3];
logic delay_buffer_sof[0:3];

/*
always_ff @( posedge i_clk, negedge i_aresetn )
  begin
   if   ( ~i_aresetn ) begin

     delay_buffer_valid <= '{default:'b0};
     delay_buffer_sof   <= '{default:'b0};

     o_data_valid       <= 1'b0;
     o_start_of_frame   <= 1'b0;

   end else begin

       delay_buffer_valid <= {i_data_valid, delay_buffer_valid[0:1]};
       delay_buffer_sof   <= {i_start_of_frame, delay_buffer_sof[0:1]};
       
       o_data_valid       <= delay_buffer_valid[2];
       o_start_of_frame   <= delay_buffer_sof[2];
   end             	
  end
 */

//let's try to use shifters from LUT
 always_ff @( posedge i_clk )
  begin

    delay_buffer_valid <= {i_data_valid, delay_buffer_valid[0:2]};
    delay_buffer_sof   <= {i_start_of_frame, delay_buffer_sof[0:2]};
       
    o_data_valid       <= delay_buffer_valid[3];
    o_start_of_frame   <= delay_buffer_sof[3];
           	
  end


//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
endmodule
