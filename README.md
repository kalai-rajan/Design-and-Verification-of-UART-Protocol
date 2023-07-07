#  Files description  
**uart_rx.sv** contains design of receiver module and linear testbench to test the receiver module.  
**uart_tx.sv** contains design of transmitter module and linear testbench to test the transmitter module.  
**uart_design_top.sv** contains the top module for the UART design module.  
**uart_tb_top.sv** contains the top module of the tb devoloped using the System Verilog Testbench Architecture.  

# Design-and-Verification-of-UART-Protocol
In this project, UART protocol is designed to send and receive 8 bit data serially using Verilog  HDL. 
A Testbench devoloped using System verilog based on Sytem verilog Testbench Architecture is used to verify the
functionality of the design. The Testbench and design are simulated using Questasim & Modelsim tools.

#Challenges  faced and its solution
The initial testbench designed using devoloped using the System Verilog Testbench Architecture appeared in a  
way that the testbench wasn't synchronized, so the some transections failed, and some transection succeded.    
After debugging the code the failure or  inappropirate results wasn't due to the TB, it was due to the error in design.
The error was the tx_done & rx_done pin in UART module arent made low, once again when new transection is initiated.    

# Simulation of design

**RECEIVER MODULE SIMULATION**    

![image](https://github.com/kalai-rajan/Design-and-Verification-of-UART-Protocol/assets/127617640/1aa06704-374d-461a-a629-d597d3b83efd)  


**TRANSMITTER MODULE SIMULATION**    

 ![image](https://github.com/kalai-rajan/Design-and-Verification-of-UART-Protocol/assets/127617640/373f7e11-870e-4a28-a027-a756850ec3c3)    


**SIMULATION RESULTS OF BOTH MODULES FOR MULTIPLEM RUNS**

 ![image](https://github.com/kalai-rajan/Design-and-Verification-of-UART-Protocol/assets/127617640/b6fff92e-5987-4812-8086-3fb86837b925)  



#  Verification of design using SV

![image](https://github.com/kalai-rajan/Design-and-Verification-of-UART-Protocol/assets/127617640/727f1804-cbd6-4b6b-8ce0-e5c1583bd7ac)

The testbench was devoloped using the System Verilog Testbench Architecture and it was executed in Questasim.

[click here to execute the Testebench code in EDA Playground](https://www.edaplayground.com/x/hJ2w).

