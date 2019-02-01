`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////


module S_AXIS_module #(

  parameter DATA_WIDTH  = 8,
  //parameter IMAGE_WIDTH = 4096,
  parameter KERNEL_SIZE = 5
  
)(

  input  logic                  i_clk,
  input  logic                  i_aresetn,

  input  logic [12:0]           IMAGE_WIDTH,

  input  logic [DATA_WIDTH-1:0] s_axis_tdata,
  input  logic                  s_axis_tvalid,
  input  logic                  s_axis_tuser,

  output logic [DATA_WIDTH-1:0] o_image_kernel_buffer [0:KERNEL_SIZE-1] [0:KERNEL_SIZE-1],
  output logic                  o_data_valid,
  output logic                  o_start_of_frame

);


/////////////////////////////
//////////////////////////////

//FIFOs (line buffers) signals

logic        rd_en_buf             [0:KERNEL_SIZE-1];
logic [7:0]  dout_line_buf         [0:KERNEL_SIZE-1];
logic [11:0] data_count_buf        [0:KERNEL_SIZE-1];

logic        prog_full_buf         [0:KERNEL_SIZE-1];
logic        full_buf              [0:KERNEL_SIZE-1];
logic        almost_full_buf       [0:KERNEL_SIZE-1];

logic        prog_empty_buf        [0:KERNEL_SIZE-1];
logic        empty_buf             [0:KERNEL_SIZE-1];
logic        almost_empty_buf      [0:KERNEL_SIZE-1];


logic [11:0] prog_full_thresh_buf;

//////////////////////////////
const logic [11:0] prog_empty_thresh_buf = 0;


assign prog_full_thresh_buf = (IMAGE_WIDTH-1) - 6; //this calculation is based on FIFO delay. 
                                               //according to testbench FIFO outputs data after 6 clks from rising edgeof rd_en
                                               //it's necessary amount of buffered pixels before starting reading out them from buffer 

//shifting through kernel_buffer when data is valid
always_ff @( posedge i_clk, negedge i_aresetn )
  begin
    if   ( ~i_aresetn ) begin
      o_image_kernel_buffer <= '{default: 'b0};
    end else begin  
     
      if ( s_axis_tvalid ) begin

        o_image_kernel_buffer[0] <= {s_axis_tdata, o_image_kernel_buffer[0][0:KERNEL_SIZE-2]};

        for ( int i = 1; i < KERNEL_SIZE-1; i++ ) begin
          o_image_kernel_buffer[i] <= {dout_line_buf[i-1], o_image_kernel_buffer[i][0:KERNEL_SIZE-2]};
        end

        o_image_kernel_buffer[KERNEL_SIZE-1] <= {dout_line_buf[KERNEL_SIZE-2], o_image_kernel_buffer[KERNEL_SIZE-1][0:KERNEL_SIZE-2]};

      end  
    end             
  end
//
//


// We use FIFO as a line buffer;
// FIFO is instantiated from xilinx-generated FIFO block, it has:
// - 8-bit input and output ports
// - depth: 4096, 
// - programmable "full treshold"
genvar j;
generate
  for ( j = 0; j < KERNEL_SIZE-1; j++ ) begin

    assign rd_en_buf[j] = prog_full_buf[j] && s_axis_tvalid; //this signal helps us to start shifting pixels though buffer at specific time, according to image_width

    fifo_generator_0 line_buffer_inst (
      .clk               ( i_clk                                   ),  // input clk
      .srst              ( ~i_aresetn                              ),  // input srst
      .din               ( o_image_kernel_buffer[j][KERNEL_SIZE-1] ),  // input [7 : 0] din
      .wr_en             ( s_axis_tvalid                           ),  // input wr_en
      .rd_en             ( rd_en_buf[j]                            ),  // input rd_en

      .prog_empty_thresh ( prog_empty_thresh_buf                   ),  // input [11 : 0] prog_empty_thresh
      .prog_full_thresh  ( prog_full_thresh_buf                    ),  // input [11 : 0] prog_full_thresh

      .dout              ( dout_line_buf[j]                        ),  // output [7 : 0] dout

      .full              ( full_buf[j]                             ),  // output full
      .almost_full       ( almost_full_buf[j]                      ),  // output almost_full
      .empty             ( empty_buf[j]                            ),  // output empty
      .almost_empty      ( almost_empty_buf[j]                     ),  // output almost_empty
      .data_count        (                                         ),  // output [11 : 0] data_count

      .prog_full         ( prog_full_buf[j]                        ),  // output prog_full, active when FIFO's received "prog_full_thresh_buf" pixels
      .prog_empty        ( prog_empty_buf[j]                       )   // output prog_empty

    );

  end 
endgenerate 
//
//


//reg these signals to sync with next module
always_ff @( posedge i_clk, negedge i_aresetn )
  begin
    if ( ~i_aresetn ) begin
      o_data_valid     <= 1'b0;
      o_start_of_frame <= 1'b0;
    end else begin
      o_data_valid     <= s_axis_tvalid;
      o_start_of_frame <= s_axis_tuser;
    end 
end 

//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
endmodule
