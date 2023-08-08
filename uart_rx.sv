module uartrx #(parameter freq=100_000_000, parameter baud_rate=9600, parameter sample=16) (clk,rst,rx,rx_done,data_reg);

input clk;
input rst;
input rx;
output reg rx_done;
output reg[7:0] data_reg;

localparam count = freq/(baud_rate*sample);


enum bit[1:0] { idle=2'd0,start=2'd1,data=2'd2, stop=2'd3}state; 


reg [3:0]data_count;
reg [4:0]sampler;
reg[9:0]baud_count;
reg baud_clock;



always @(posedge clk or posedge rst) begin
    if (rst) begin
        baud_count<=10'd0;
        baud_clock<=1'b0;
        
     end

    else if (baud_count==count) begin
         baud_count<=10'd0;
         baud_clock<=1'b1;
     end

    else if (baud_count==count/2) begin
         baud_count<=baud_count+1'b1;
         baud_clock<=1'b0;
     end

     else begin
        baud_count<=baud_count+1'b1;
     end
end

always @(posedge baud_clock or posedge rst) begin
    if (rst) begin  
        state<=idle;
        data_count<=4'd0;
        data_reg<=8'b0;
        sampler<=5'd0;
        rx_done<=0;
     end
     else 
		  case (state)

            idle: begin
                
                if(rx==1'b0) begin
                 state<=start;
                 sampler<=sampler+1'b1;
                end
                 else 
                    state <=idle;
            end
            
            start: begin
                if (sampler==sample/2 && rx==1'b0) begin
                    state<=data;
                    sampler<=5'd0;
                end
                else begin
                    sampler<=sampler+1'b1;
                    state<=start;
                end
                     
            end

            data: begin
                if(data_count==4'd8) begin
                    
                    sampler<=5'd1;
                    state<=stop;
                end
                else begin
                    if(sampler==sample-1) begin
                        sampler<=5'd0;
                        case (data_count)
                           4'd0 : data_reg[0]<=rx;
                           4'd1 : data_reg[1]<=rx;
                           4'd2 : data_reg[2]<=rx;
                           4'd3 : data_reg[3]<=rx;
                           4'd4 : data_reg[4]<=rx;
                           4'd5 : data_reg[5]<=rx;
                           4'd6 : data_reg[6]<=rx; 
                           4'd7 : data_reg[7]<=rx;
                        endcase
                        data_count<=data_count+1'b1;
                    end
                    else begin
                         sampler<=sampler+1;
                    end
                    state<=data;
                end 
            end

             stop:  begin 

                if (sampler==sample-1 && rx==1'b1) begin
                    state<=idle;
                    data_count<=4'd0;
                    rx_done<=1'b1;
                    sampler<=5'd0;
                end
                else begin
                    sampler<=sampler+1'b1;
                    state<=stop;
                end
                     
            end
                     
        endcase
    end

endmodule


module ref_clcok(clk,rst);

input clk;
input rst;
reg sclk;

reg [13:0]scount;

parameter freq=100_000_000;
parameter baud_rate=9600; 
parameter sample=16;
localparam count=  freq/baud_rate;

always @(posedge clk or posedge rst) begin
    
    if(rst) begin
        scount<=0;
        sclk<=1'b0;
    end

    else if(scount==count/2) begin
        sclk<=1'b1;
        scount<=scount+1'b1;
    end
    else if(scount==count) begin
        sclk<=1'b0;
        scount<=0;
    end
    else 
     scount<=scount+1'b1;

end

endmodule

module  uartrx_tb;

wire sclk;
reg clk,rst;
reg [7:0]data_in;
int i;
reg rx_in;
wire rx_done;
wire [7:0]rx_out;


ref_clcok dut1(clk,rst);
uartrx dut2(.clk(clk), .rst(rst), .rx(rx_in), .rx_done(rx_done), .data_reg(rx_out));



initial begin

    rst=1; clk=0;i=0;data_in=8'b1001_1001;
    @(posedge clk);
    rst=0; 
    @(posedge dut1.sclk);
    rx_in=1;
    @(posedge dut1.sclk);
    rx_in=0;

    repeat(8) begin
        @(posedge dut1.sclk);
         rx_in=data_in[i];
         i++;
    end
    @(posedge dut1.sclk);
    @(posedge dut1.sclk);
    if(rx_done) begin

    if(rx_out==data_in) begin
     $display("TRANSMITTER DATA SENDED=%b\tRECEIVER DATA=%b",data_in,rx_out);
     $display("DATA MATCHED IN RECEIVER");
    end
    else begin
     $display("TRANSMITTER DATA SENDED=%b\tRECEIVER DATA=%b",data_in,rx_out);
     $display("DATA MISSMATCHED IN RECEIVER");
    end
    end

    else 
     $display("RX_DONE DIDNT WORKED PROPERLY");
end
always #5 clk=~clk;

endmodule

