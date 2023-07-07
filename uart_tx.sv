module uarttx #(parameter freq=100_000_000, parameter baud_rate=9600) (clk,rst,tx_in,send,tx_done,tx);

localparam count=freq/baud_rate;  //for creating clock as per baudrate

input clk,rst,send;
input [7:0]tx_in;
output reg tx,tx_done;


reg uclk;            //slowed down clock matching the baud rate
reg [13:0]count1;   // localparam width=$clog2(count); [width-1:0]
reg[3:0] data_count; 
enum bit[1:0] {idle=2'd0, start=2'd1, transfer=2'd2,stop=2'd3}state;

always @(posedge clk or posedge rst) begin
    
    if(rst) begin
        count1<=0;
        uclk<=1'b0;
    end
    else if(count1==count/2) begin
        uclk<=1'b1;
        count1<=count1+1'b1;
    end
    else if(count1==count) begin
        uclk<=1'b0;
        count1<=0;
    end
    else 
     count1<=count1+1'b1;

end

always @(posedge uclk or posedge rst ) begin
    if(rst) begin
        tx<=1'b1;
        tx_done<=1'b0;
        data_count<=0;
        state<=idle;
    end

    else begin
        case (state)
            idle: begin

                if(send) begin
                    state<=transfer;
                    tx<=1'b0;
                end
                else begin
                    state<=idle;
                end

            end 

            transfer: begin

                if(data_count==4'd8) begin
                    data_count<=3'd0;
                    state<=stop;
                end

                else begin

                    data_count<=data_count+1'b1;
                    case (data_count) 
                        4'd0: tx<=tx_in[0];
                        4'd1: tx<=tx_in[1];
                        4'd2: tx<=tx_in[2];
                        4'd3: tx<=tx_in[3];
                        4'd4: tx<=tx_in[4]; 
                        4'd5: tx<=tx_in[5];
                        4'd6: tx<=tx_in[6];
                        4'd7: tx<=tx_in[7];    
                    endcase
                      
                    state<=transfer;
                end
            end

            stop: begin
                tx<=1'b1;
                tx_done<=1'b1;
                state<=idle;                        
            end
            
        endcase
    end
end

endmodule

module uarttx_tb;
reg clk,rst;
reg send;
reg [7:0]data_in;
wire tx,tx_done;
reg [7:0]data_verif;
int i;
wire rx_done;
wire [7:0]rx_out;

uarttx dut(clk,rst,data_in,send,tx_done,tx);
uartrx dut2(clk,rst,tx,rx_done,rx_out);

initial begin
    rst=1; clk=0;i=0;
    data_in<=8'b1001_1001;

    @(posedge clk);
    rst=0; 
    repeat (5) begin
        @(posedge dut.uclk);
        send=1;
        @(posedge dut.uclk);
        send=0;
        @(posedge dut.uclk);

        repeat(8) begin
            @(posedge dut.uclk);
            data_verif[i]=tx;
            i++;
        end
        @(posedge dut.uclk);
        @(posedge dut.uclk);

        if(data_verif==data_in) begin
        $display("TRANSMITTER DATA SENDED=%b\tTRANSMITERDATA RECEIVED=%b",data_in,data_verif);
        $display("DATA MATCHED IN TRANSMITTER");
        end
        else begin
        $display("TRANSMITTER DATA SENDED=%b\tTRANSMITERDATA RECEIVED=%b",data_in,data_verif);
        $display("DATA MISSMATCHED IN TRANSMITTER");
        end

        if(rx_out==data_in) begin
        $display("TRANSMITTER DATA SENDED=%b\tRECEIVER DATA=%b",data_in,rx_out);
        $display("DATA MATCHED IN RECEIVER\n");
        end
        else begin
        $display("TRANSMITTER DATA SENDED=%b\tRECEIVER DATA=%b",data_in,rx_out);
        $display("DATA MISSMATCHED IN RECEIVER\n");
        end
    end
    $finish();
end
always #5 clk=~clk;
endmodule