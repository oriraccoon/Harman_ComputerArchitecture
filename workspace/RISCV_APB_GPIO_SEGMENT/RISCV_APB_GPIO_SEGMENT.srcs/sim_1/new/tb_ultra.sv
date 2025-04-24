`timescale 1ns / 1ps

module tb_Ultrasonic_Periph;
    // Inputs
    reg PCLK;
    reg PRESET;
    reg [3:0] PADDR;
    reg [31:0] PWDATA;
    reg PWRITE;
    reg PENABLE;
    reg PSEL;
    reg echo;

    // Outputs
    wire [31:0] PRDATA;
    wire PREADY;
    wire trig;
    wire o_PCLK; // Divided clock

    // Instantiate the unit under test (UUT)
    Ultrasonic_Periph UUT (
        .PCLK(PCLK),
        .PRESET(PRESET),
        .PADDR(PADDR),
        .PWDATA(PWDATA),
        .PWRITE(PWRITE),
        .PENABLE(PENABLE),
        .PSEL(PSEL),
        .PRDATA(PRDATA),
        .PREADY(PREADY),
        .echo(echo),
        .trig(trig)
    );

    // Generate PCLK
    always begin
        #5 PCLK = ~PCLK;  // PCLK 100MHz, period = 10ns
    end

    initial begin
        // Initialize signals
        PCLK = 0;
        PRESET = 1;
        PSEL = 0;
        PWRITE = 0;
        PENABLE = 0;
        PADDR = 0;
        PWDATA = 0;
        echo = 0;

        // Apply reset
        repeat (2) @(posedge PCLK);
        PRESET = 0;

        // Simulate some delay
        #100;

        // Test: Trigger ultrasound
        // Wait until `trig` goes high (indicates that UUT is ready)
        wait (trig == 1);
        @(posedge PCLK);  // sync with clock

        // Now simulate the echo response
        echo = 1;
        #5000;  // Echo signal lasts for a short time (~10us)
        echo = 0;

        // Wait for distance measurement to finish (UUT should go back to IDLE state)
        #10000;

        // Read the PRDATA register (distance value)
        apb_read(4'h0);

        // Print the distance
        $display("Distance: %d cm", PRDATA);

        // Finish the simulation
        $finish;
    end

    // APB read procedure
    task apb_read;
        input [3:0] addr;
        begin
            PSEL = 1;
            PENABLE = 0;
            PADDR = addr;
            @(posedge PCLK);  // sync to clock
            PENABLE = 1;
            @(posedge PCLK);  // sync again
            PSEL = 0;  // disable selection
        end
    endtask

endmodule
