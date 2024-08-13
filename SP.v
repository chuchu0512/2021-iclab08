`timescale 1ns / 1ps
module SP(
input clk,
input rstn,
input in_valid,
input [15:0] in_data,
input [2:0] in_mode,
output reg out_valid,
output reg [15:0] out_data
    );
    
    parameter IDLE       = 3'b000 ;
    parameter READ_IN    = 3'b001 ;
    parameter MMI        = 3'b010 ;
    parameter MM         = 3'b011 ; 
    parameter SORTING    = 3'b100 ;
    parameter SUM        = 3'b101 ;
    parameter READ_OUT   = 3'b110 ;
    
    reg [2:0] cs, ns ;
    
    reg [2:0] mode[0:2] ;
    reg [15:0] A[0:5] ;
    reg [15:0] B[0:5] ;
    reg [15:0] C[0:5] ;
    reg [15:0] D[0:5] ;
    reg [15:0] E[0:5] ;
    
    reg [3:0] cnt_read_in ;
    reg [5:0] cnt_mmi ;
    reg [3:0] cnt_sorting ;
    reg [3:0] cnt_read_out ;
    
    //==========
    //state
    //==========
    
    always@(posedge clk)begin
        if(!rstn) cs <= IDLE ;
        else cs <= ns ;
    end
    
    always@(*)begin
        case(cs)
            IDLE:begin
                if(in_valid) ns = READ_IN ;
                else ns = IDLE ;
            end
            READ_IN:begin
                if(in_valid == 1 && cnt_read_in == (9-1)) ns = MMI ; // mode(3) + A(6)
                else ns = READ_IN ;
            end
            MMI:begin
                if(cnt_mmi == 55) ns = MM ;//cnt_mmi = 55 = 110(6)_111(7)
                else ns = MMI ;
            end
            MM:begin
                ns = SORTING ;
            end
            SORTING:begin
                if(cnt_sorting == 5) ns = SUM ;
                else ns = SORTING ;
            end
            SUM:begin
                ns = READ_OUT ;
            end
            READ_OUT:begin
                if(cnt_read_out == 5) ns = IDLE ;
                else ns = READ_OUT ;
            end
            default: ns = IDLE ;
        endcase
    end
    
    //==========
    //cnt
    //==========
    
    always@(posedge clk)begin
        if(!rstn) cnt_read_in <= 0 ;
        else begin
            if(cs == READ_IN && in_valid == 1) cnt_read_in <= cnt_read_in + 1 ;
            else cnt_read_in <= 0 ;
        end
    end
    
    always@(posedge clk)begin
        if(!rstn) cnt_mmi <= 0 ;
        else begin
            if(cs == MMI) cnt_mmi <= cnt_mmi + 1 ;
            else cnt_mmi <= 0 ;
        end
    end
    
    always@(posedge clk)begin
        if(!rstn) cnt_sorting <= 0 ;
        else begin
            if(cs == SORTING) cnt_sorting <= cnt_sorting + 1 ;
            else cnt_sorting <= 0 ;
        end
    end
    
    always@(posedge clk)begin
        if(!rstn) cnt_read_out <= 0 ;
        else begin
            if(out_valid == 1 && cs == READ_OUT) cnt_read_out <= cnt_read_out + 1 ;
            else cnt_read_out <= cnt_read_out ;
        end
    end
    
    //==========
    //READ_IN
    //==========
    integer i ;
    //mode
    always@(posedge clk)begin
        if(!rstn) begin
            for(i=0; i<3; i=i+1)begin
                mode[i] <= 0 ;
            end
        end
        else begin
            if(in_valid == 1 && cnt_read_in<3) mode[cnt_read_in] <= in_mode ;
        end
    end
    //A
    always@(posedge clk)begin
        if(!rstn)begin
            for(i=0; i<6; i=i+1)begin
                A[i] <= 0 ;
            end
        end
        else begin
            case(cs)
                READ_IN:begin
                    if(in_valid == 1 && cnt_read_in>2) A[cnt_read_in-3] <= in_data ;
                end
                default:begin
                    A[0] <= A[0] ;
                    A[1] <= A[1] ;
                    A[2] <= A[2] ;
                    A[3] <= A[3] ;
                    A[4] <= A[4] ;
                    A[5] <= A[5] ;
                end   
            endcase
        end
    end
    
    //==========
    //MMI
    //==========
    reg signed[15:0] T1[0:7] ;
    reg signed[15:0] T2[0:7] ;
    reg signed[15:0] A0[0:7] ;
    reg signed[15:0] B0[0:7] ;
    reg signed[15:0] R [0:7] ;
    reg signed[15:0] Q [0:7] ;
    
    always@(posedge clk)begin
        if(!rstn)begin
            for(i=0; i<6; i=i+1)begin
                B[i] <= 0 ;
            end
        end
        else begin
            case(cs)
                MMI:begin
                    if(mode[0] == 0)begin
                        B[0] <= A[0] ;
                        B[1] <= A[1] ;
                        B[2] <= A[2] ;
                        B[3] <= A[3] ;
                        B[4] <= A[4] ;
                        B[5] <= A[5] ;
                    end
                    else begin
                        if(cnt_mmi[2:0] == 0)begin
                            T1[cnt_mmi[2:0]] = 0 ;
                            T2[cnt_mmi[2:0]] = 1 ;
                            A0[cnt_mmi[2:0]] = 509 ;
                            B0[cnt_mmi[2:0]] = A[cnt_mmi[5:3]] ;
                            R [cnt_mmi[2:0]] = A0[cnt_mmi[2:0]]%B0[cnt_mmi[2:0]] ;
                            Q [cnt_mmi[2:0]] = A0[cnt_mmi[2:0]]/B0[cnt_mmi[2:0]] ;
                        end
                        else begin
                            if(R[cnt_mmi[2:0] - 1] != 0)begin
                                T1[cnt_mmi[2:0]] = T2[cnt_mmi[2:0] - 1] ;
                                T2[cnt_mmi[2:0]] = T1[cnt_mmi[2:0] - 1] - Q[cnt_mmi[2:0] - 1]*T2[cnt_mmi[2:0] - 1] ;
                                A0[cnt_mmi[2:0]] = B0[cnt_mmi[2:0] - 1] ;
                                B0[cnt_mmi[2:0]] = R [cnt_mmi[2:0] - 1] ;
                                R [cnt_mmi[2:0]] = A0[cnt_mmi[2:0]]%B0[cnt_mmi[2:0]] ;
                                Q [cnt_mmi[2:0]] = A0[cnt_mmi[2:0]]/B0[cnt_mmi[2:0]] ;
                            end
                            else begin
                                T1[cnt_mmi[2:0]] = T1[cnt_mmi[2:0] - 1] ;
                                T2[cnt_mmi[2:0]] = T2[cnt_mmi[2:0] - 1] ;
                                A0[cnt_mmi[2:0]] = A0[cnt_mmi[2:0] - 1] ;
                                B0[cnt_mmi[2:0]] = B0[cnt_mmi[2:0] - 1] ;
                                R [cnt_mmi[2:0]] = R [cnt_mmi[2:0] - 1] ;
                                Q [cnt_mmi[2:0]] = Q [cnt_mmi[2:0] - 1] ;
                                if(T2[cnt_mmi[2:0] - 1] <  0) B[cnt_mmi[5:3]] <= T2[cnt_mmi[2:0] - 1] + 509 ;
                                else B[cnt_mmi[5:3]] <= T2[cnt_mmi[2:0] - 1] ;
                            end
                        end
                    end
                end
                default:begin
                    B[0] <= B[0] ;
                    B[1] <= B[1] ;
                    B[2] <= B[2] ;
                    B[3] <= B[3] ;
                    B[4] <= B[4] ;
                    B[5] <= B[5] ;
                end
            endcase
        end
    end
    
    //==========
    //MM
    //==========
    
    reg [31:0]mm[0:5] ;
    always@(posedge clk)begin
        if(!rstn)begin
            for(i=0; i<6; i=i+1)begin
                C[i] <= 0 ;
            end
        end
        else begin
            case(cs)
                MM:begin
                    if(mode[1] == 0)begin
                        C[0] <= B[0] ;
                        C[1] <= B[1] ;
                        C[2] <= B[2] ;
                        C[3] <= B[3] ;
                        C[4] <= B[4] ;
                        C[5] <= B[5] ;
                    end
                    else begin
                        mm[0] = (((((((B[1]*B[2])%509)*B[3])%509)*B[4])%509)*B[5])%509 ;
                        mm[1] = (((((((B[0]*B[2])%509)*B[3])%509)*B[4])%509)*B[5])%509 ;
                        mm[2] = (((((((B[0]*B[1])%509)*B[3])%509)*B[4])%509)*B[5])%509 ;
                        mm[3] = (((((((B[0]*B[1])%509)*B[2])%509)*B[4])%509)*B[5])%509 ;
                        mm[4] = (((((((B[0]*B[1])%509)*B[2])%509)*B[3])%509)*B[5])%509 ;
                        mm[5] = (((((((B[0]*B[1])%509)*B[2])%509)*B[3])%509)*B[4])%509 ;
                        C[0] <= mm[0][15:0] ;
                        C[1] <= mm[1][15:0] ;
                        C[2] <= mm[2][15:0] ;
                        C[3] <= mm[3][15:0] ;
                        C[4] <= mm[4][15:0] ;
                        C[5] <= mm[5][15:0] ;                        
                    end
                end
                default:begin
                    C[0] <= C[0] ;
                    C[1] <= C[1] ;
                    C[2] <= C[2] ;
                    C[3] <= C[3] ;
                    C[4] <= C[4] ;
                    C[5] <= C[5] ;
                end
            endcase
        end
    end
    
    //==========
    //SORTING
    //==========
    wire [15:0] S [0:5] ;
    sort6 sort15(.in0(C[0]), .in1(C[1]), .in2(C[2]), .in3(C[3]), .in4(C[4]), .in5(C[5]),
                .out0(S[0]), .out1(S[1]), .out2(S[2]), .out3(S[3]), .out4(S[4]), .out5(S[5])) ;
    
    always@(posedge clk)begin
        if(!rstn)begin
            for(i=0; i<6; i=i+1)begin
                D[i] <= 0 ;
            end
        end
        else begin
            case(cs)
                SORTING:begin
                    if(mode[2] == 0)begin
                        D[0] <= C[0] ;
                        D[1] <= C[1] ;
                        D[2] <= C[2] ;
                        D[3] <= C[3] ;
                        D[4] <= C[4] ;
                        D[5] <= C[5] ;
                    end
                    else begin
                        if(cnt_sorting == 5)begin
                            D[0] <= S[0] ;
                            D[1] <= S[1] ;
                            D[2] <= S[2] ;
                            D[3] <= S[3] ;
                            D[4] <= S[4] ;
                            D[5] <= S[5] ;
                        end
                        else begin
                            D[0] <= D[0] ;
                            D[1] <= D[1] ;
                            D[2] <= D[2] ;
                            D[3] <= D[3] ;
                            D[4] <= D[4] ;
                            D[5] <= D[5] ;
                        end
                    end
                end
                default:begin
                    D[0] <= D[0] ;
                    D[1] <= D[1] ;
                    D[2] <= D[2] ;
                    D[3] <= D[3] ;
                    D[4] <= D[4] ;
                    D[5] <= D[5] ;
                end
            endcase
        end
    end
    
    //==========
    // SUM
    //==========
    reg [20:0] sum [0:5] ;
    always@(posedge clk)begin
        if(!rstn)begin
            for(i=0; i<6; i=i+1)begin
                E[i] <= 0 ;
            end
        end
        else begin
            case(cs)
                SUM:begin
                    sum[0] = (A[0]+B[0]+C[0]+D[0])%509 ;
                    sum[1] = (A[1]+B[1]+C[1]+D[1])%509 ;
                    sum[2] = (A[2]+B[2]+C[2]+D[2])%509 ;
                    sum[3] = (A[3]+B[3]+C[3]+D[3])%509 ;
                    sum[4] = (A[4]+B[4]+C[4]+D[4])%509 ;
                    sum[5] = (A[5]+B[5]+C[5]+D[5])%509 ;
                    E[0] <= sum[0] ;
                    E[1] <= sum[1] ;
                    E[2] <= sum[2] ;
                    E[3] <= sum[3] ;
                    E[4] <= sum[4] ;
                    E[5] <= sum[5] ;
                end
                default:begin
                    E[0] <= E[0] ;
                    E[1] <= E[1] ;
                    E[2] <= E[2] ;
                    E[3] <= E[3] ;
                    E[4] <= E[4] ;
                    E[5] <= E[5] ;
                end
            endcase
        end
    end
    
    //==========
    // READ_OUT
    //==========
    always@(posedge clk)begin
        if(!rstn) out_valid <= 0 ;
        else begin
            if(cs == READ_OUT) out_valid <= 1 ;
            else out_valid <= 0 ;
        end
    end
    
    always@(posedge clk)begin
        if(!rstn) out_data <= 0 ;
        else begin
            case(cs)
                READ_OUT:begin
                    if(out_valid == 1) out_data <= E[cnt_read_out] ;
                end
                default:out_data <= 0 ;
            endcase
        end
    end
endmodule

module sort6
(
    input [15:0] in0, in1, in2, in3, in4, in5,
    output [15:0] out0, out1, out2, out3, out4, out5
) ;
    wire [15:0] s10, s11, s12, s13, s14, s15 ;
    wire [15:0] s20, s21, s22, s23, s24, s25 ;
    wire [15:0] s30, s31, s32, s33, s34, s35 ;
    wire [15:0] s40, s41, s42, s43, s44, s45 ;
    wire [15:0] s50, s51, s52, s53, s54, s55 ;
    assign s20 = s10 ;
    assign s25 = s15 ;
    assign s40 = s30 ;
    assign s45 = s35 ;
    assign out0 = s50 ;
    assign out5 = s55 ;
    // layer1
    sort2 sort0(.in0(in0), .in1(in1), .out0(s10), .out1(s11)) ;
    sort2 sort1(.in0(in2), .in1(in3), .out0(s12), .out1(s13)) ;
    sort2 sort2(.in0(in4), .in1(in5), .out0(s14), .out1(s15)) ;
    // layer2
    sort2 sort3(.in0(s11), .in1(s12), .out0(s21), .out1(s22)) ;
    sort2 sort4(.in0(s13), .in1(s14), .out0(s23), .out1(s24)) ;
    // layer3
    sort2 sort5(.in0(s20), .in1(s21), .out0(s30), .out1(s31)) ;
    sort2 sort6(.in0(s22), .in1(s23), .out0(s32), .out1(s33)) ;
    sort2 sort7(.in0(s24), .in1(s25), .out0(s34), .out1(s35)) ;
    // layer4
    sort2 sort8(.in0(s31), .in1(s32), .out0(s41), .out1(s42)) ;
    sort2 sort9(.in0(s33), .in1(s34), .out0(s43), .out1(s44)) ;
    // layer5
    sort2 sort10(.in0(s40), .in1(s41), .out0(s50), .out1(s51)) ;
    sort2 sort11(.in0(s42), .in1(s43), .out0(s52), .out1(s53)) ;
    sort2 sort12(.in0(s44), .in1(s45), .out0(s54), .out1(s55)) ;
    // layer6
    sort2 sort13(.in0(s51), .in1(s52), .out0(out1), .out1(out2)) ;
    sort2 sort14(.in0(s53), .in1(s54), .out0(out3), .out1(out4)) ;
endmodule

module sort2
(
    input [15:0] in0, in1,
    output reg [15:0] out0, out1
) ;
    always@(*)begin
        if(in0 > in1)begin
            out0 <= in1 ;
            out1 <= in0 ;
        end
        else begin
            out0 <= in0 ;
            out1 <= in1 ;
        end
    end
endmodule