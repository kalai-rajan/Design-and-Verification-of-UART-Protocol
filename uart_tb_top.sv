class transaction;

    typedef enum bit [1:0] {write = 2'b00 , read = 2'b01} oper_type;
    randc oper_type oper;
    bit tx,rx,send;
    randc bit[7:0]tx_in,rx_in;
    bit [7:0]rx_out;
    bit rx_done,tx_done;


    function void display(string s);    
      $display("%s\t\tOPER=%0s TX_IN=(%0d) RX_IN=(%0d) @%0d",s,oper.name(),tx_in,rx_in,$time/10_000);
    endfunction

endclass
//--------------------------------------------------------------------------------------------------------------------------------------------------
class generator;

  mailbox #(transaction) gen2driv;
  mailbox gen2cov;
    int repeat_no;
    event drivnext;
    event scbnext;
    event ended;
    int i;

  function new(mailbox #(transaction) gen2driv, mailbox gen2cov);
        this.gen2driv=gen2driv;
        this.gen2cov=gen2cov;
    endfunction

    task main();
        transaction t;
        t=new();
        i=1;
        repeat(repeat_no) begin
            
            if(!t.randomize)
              $fatal("RANDOMIZATION FAILED");
            else begin
              $display("TRANSECTION NUMBER = %0d",i);
              t.display("GENERATOR ");
            end
          gen2driv.put(t);
          gen2cov.put(t);
          i++;
             @(scbnext);
        end
        ->ended;
    endtask
endclass
//--------------------------------------------------------------------------------------------------------------------------------------------------
class driver;
  mailbox #(transaction)gen2driv;
    mailbox #(bit [7:0]) driv2scb;
    event drivnext;
    int no_trans=0;
    virtual intf intf_h;
    int i;
    bit[7:0] din;

  function new(mailbox #(transaction) gen2driv, mailbox #(bit [7:0]) driv2scb,virtual intf intf_h);
        this.gen2driv=gen2driv;
        this.driv2scb=driv2scb;
        this.intf_h=intf_h;
    endfunction

    task reset();
        $display("\nRESET STARTED");
        intf_h.rst<=1;
        intf_h.send<=0;
        intf_h.rx<=1'b1;
        intf_h.tx_in<=0;
      repeat(30_000)@(posedge intf_h.clk);
        intf_h.rst<=0;
      $display("RESET FINISHED");
    endtask

    task main();
        transaction t;
        forever begin
            gen2driv.get(t);
          @(posedge intf_h.uclk);  
     
          if(t.oper==2'b00)begin
                driv2scb.put(t.tx_in);  
                intf_h.send<=1'b1;
                intf_h.rx<=1'b1;
                intf_h.tx_in<=t.tx_in;
                @(posedge intf_h.uclk);
                intf_h.send<=1'b0;
            wait(intf_h.tx_done==1);
            $display("DRIVER    \t\tSENDED DATA IN UART TX IS %0d   \t@%0d",t.tx_in,$time/10_000);
                wait(intf_h.tx_done);
                
            end
            
            else if(t.oper==2'b01) begin
              
              	driv2scb.put(t.rx_in);
                intf_h.send<=0;
                intf_h.rx<=1'b0;
                intf_h.tx_in<=0;
              	$display("DRIVER    \t\tSENDED DATA IN UART RX IS %0d   \t@%0d",t.rx_in,$time/10_000);
                for(int i=0;i<8;i++) begin
                   @(posedge intf_h.uclk);
                  intf_h.rx<=t.rx_in[i];
                end
                @(posedge intf_h.uclk);
                intf_h.rx<=1'b1;
              wait(intf_h.rx_done==1);  
                
            end
        end
    endtask


endclass
//--------------------------------------------------------------------------------------------------------------------------------------------------
class monitor;
    mailbox #(bit[7:0]) mon2scb;
    bit [7:0]dscb;
    int no_trans;
    virtual intf intf_h;
    int i;
    transaction t;

     function new(mailbox #(bit [7:0]) mon2scb,virtual intf intf_h);
        this.mon2scb=mon2scb;
        this.intf_h=intf_h;
        t=new();
    endfunction

    task main();
      forever begin
        
         @(posedge intf_h.uclk);
        
        if( (intf_h.send==1) && (intf_h.rx==1) ) begin
             for (i =0 ;i<8 ;i++ ) begin
                @(posedge intf_h.uclk);
                dscb[i] <= intf_h.tx; 
            end
            wait(intf_h.tx_done);
            $display("MONITOR   \t\tRECEIVED DATA FROM UART TX IS %0d @%0d",dscb,$time/10_000);
            mon2scb.put(dscb);
          
        end
        
       else if ((intf_h.send==0) && (intf_h.rx==0))begin
          	wait(intf_h.rx_done);
            dscb=intf_h.rx_out;
            mon2scb.put(dscb);
          	$display("MONITOR   \t\tRECEIVED DATA FROM UART RX IS %0d @%0d",dscb,$time/10_000);
           @(posedge intf_h.uclk);
          
        end
        
      end
       
    endtask

endclass
//--------------------------------------------------------------------------------------------------------------------------------------------------
class coverage;
    transaction t;
    mailbox gen2cov;
    covergroup cg;
      c1: coverpoint   t.tx_in;
      c2: coverpoint   t.rx_in;
      c3: coverpoint   t.oper{bins b0={2'd0}; bins b1={2'd1}; }
      c4: cross c1,c3;
      c5: cross c2,c3;
        
    endgroup

  function new(mailbox gen2cov);
    	this.gen2cov=gen2cov; 
        t=new();
   	 	cg=new();
    endfunction

    task main();
      forever begin
       gen2cov.get(t);
       cg.sample(); 
      end
    endtask

    task display();
      $display("COVERAGE=%f",cg.get_coverage());
    endtask

endclass
//--------------------------------------------------------------------------------------------------------------------------------------------------
class scoreboard;
    mailbox #(bit [7:0])mon2scb;
    mailbox #(bit [7:0])driv2scb;
    event scbnext;
    int no_trans;
    bit [7:0]tx;
    bit [7:0]rx;
  int q[$];
  int i=1;

      function new(mailbox #(bit [7:0]) mon2scb, mailbox #(bit [7:0]) driv2scb);
        this.driv2scb=driv2scb;
        this.mon2scb=mon2scb;
    endfunction

    task main();
        forever begin
            driv2scb.get(tx);
            mon2scb.get(rx);
            if(tx==rx) begin
              $display("SCOREBOARD\t\tUART VERIFICATION IS SUCESS   \t@%0d\n",$time/10_000);
              
            end
        
            else begin
              $display("SCOREBOARD\t\tUART VERIFICATION IS FAILED   \t@%0d\n",$time/10_000);
              q.push_front(i);
            end
            ->scbnext;
            
        end
    endtask
  
  task report_g;
     transaction t;
      int i;
      int temp;
      
      if(q.size()) begin
        $display("The  Failed Transections Numbers are ");
          foreach (q[i]) begin
            $display("%0d",q[i]);
          end
      end
      else
        $display("Passed all testcases");
    endtask
  
endclass
//--------------------------------------------------------------------------------------------------------------------------------------------------

class environment;
    mailbox #(transaction) gen2driv;
    mailbox # (bit[7:0]) driv2scb;
    mailbox # (bit[7:0]) mon2scb;
  	mailbox gen2cov;

    event nextgd;
    event nextgs;
    generator g;
    driver d;
    monitor m;
    scoreboard s;
  	coverage c;
    virtual intf intf_h;

    function new(virtual intf intf_h);
        this.intf_h=intf_h;
        gen2driv=new();
        driv2scb=new();
        mon2scb=new();
      	gen2cov=new();

      g=new(gen2driv,gen2cov);
        d=new(gen2driv,driv2scb,intf_h);
        m=new(mon2scb,intf_h);
        s=new(mon2scb,driv2scb);
      c=new(gen2cov);

        g.drivnext=nextgd;
        d.drivnext=nextgd;
        g.scbnext=nextgs;
        s.scbnext=nextgs;
    endfunction

    task pre_test();
        d.reset();
    endtask

    task test();
        fork
            g.main();
            d.main();
          m.main();
           s.main();
           c.main();
        join_any
    endtask

    task post_test();
        wait(g.ended.triggered);
         $display("-------------------------------------------------------------------------------");
        s.report_g();
       $display("-------------------------------------------------------------------------------");
        c.display();
      $display("-------------------------------------------------------------------------------");
        $finish();
         
    endtask

    task run();
         pre_test();
         test();
         post_test();
    endtask

endclass
//--------------------------------------------------------------------------------------------------------------------------------------------------
program test(intf intf_h);
    environment e;
    initial begin
        e=new(intf_h);
        e.g.repeat_no=500;
        e.run();

    end
endprogram
//--------------------------------------------------------------------------------------------------------------------------------------------------
module tb;
    
    bit clk,rst;

    initial begin
        clk=0;
        forever #5 clk=~clk;
    end

    initial begin
      repeat(2) @(posedge clk);
    end
  
	initial begin
      $dumpfile("dump.vcd");
      $dumpvars;
    end
  
    intf intf_h(clk);
    test a(intf_h);
     
     uart_design_top dut (.clk(intf_h.clk), .rst(intf_h.rst), .tx(intf_h.tx), .tx_in(intf_h.tx_in), .send(intf_h.send), 
     .tx_done(intf_h.tx_done), .rx(intf_h.rx), .rx_done(intf_h.rx_done), .rx_out(intf_h.rx_out) );

     assign intf_h.uclk=dut.utx.uclk;

endmodule
