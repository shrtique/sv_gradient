`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////


module S_AXIS_module #(

  parameter DATA_WIDTH  = 8,
  parameter KERNEL_SIZE = 5,
  parameter IMAGE_WIDTH = 4096
)(

  input  logic                  i_clk,
  input  logic                  i_aresetn,

  input  logic [DATA_WIDTH-1:0] s_axis_tdata,
  input  logic                  s_axis_tvalid,
  input  logic                  s_axis_tuser,

  output logic [DATA_WIDTH-1:0] o_image_kernel_buffer [0:KERNEL_SIZE-1] [0:KERNEL_SIZE-1],
  output logic                  o_data_valid,
  output logic                  o_start_of_frame

);


//signals
typedef logic [DATA_WIDTH-1:0] type_line_buffer [0:KERNEL_SIZE-2] [0:( IMAGE_WIDTH - KERNEL_SIZE )-1];
type_line_buffer line_buffer_array;
//
//

//shifting through kernel_buffer when data is valid
always_ff @( posedge i_clk, negedge i_aresetn )
  begin
    if   ( ~i_aresetn ) begin
      o_image_kernel_buffer <= '{default: 'b0};
      line_buffer_array     <= '{default: 'b0};
    end else begin	
     
      if ( s_axis_tvalid ) begin

        o_image_kernel_buffer[0] <= {s_axis_tdata, o_image_kernel_buffer[0][0:KERNEL_SIZE-2]};
        line_buffer_array[0]     <= {o_image_kernel_buffer[0][KERNEL_SIZE-1], line_buffer_array[0][0:( IMAGE_WIDTH - KERNEL_SIZE )-2]};
 
        for ( int i = 1; i < KERNEL_SIZE-1; i++ ) begin
          o_image_kernel_buffer[i] <= {line_buffer_array[i-1][(IMAGE_WIDTH - KERNEL_SIZE)-1],o_image_kernel_buffer[i][0:KERNEL_SIZE-2]};
          line_buffer_array[i]     <= {o_image_kernel_buffer[i][KERNEL_SIZE-1], line_buffer_array[i][0:( IMAGE_WIDTH - KERNEL_SIZE )-2]};
        end  

        o_image_kernel_buffer[KERNEL_SIZE-1] <= {line_buffer_array[KERNEL_SIZE-2][(IMAGE_WIDTH - KERNEL_SIZE)-1],o_image_kernel_buffer[KERNEL_SIZE-1][0:KERNEL_SIZE-2]};
        
      end  
    end             
  end
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
