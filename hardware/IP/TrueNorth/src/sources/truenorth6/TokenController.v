`timescale 1ns / 1ns

//////////////////////////////////////////////////////////////////////////////////
// TokenController.v
//
// Created for Dr. Akoglu's Reconfigurable Computing Lab
// at the University of Arizona
// 
// Handles communication between the Scheduler, CSRAM and Neuron Block to facilitate all neuron computation.
//すべてのニューロン計算を容易にするために、スケジューラ、CSRAM、ニューロン・ブロック間の通信を処理する。

// ABBREVIATIONS:(略語)
// TC = Token Controller
// NB = Neuron Block
// SSRAM = Scheduler SRAM
// CSRAM = Core SRAM
//
// NOTES:
// ROW: A row refers to an AXON.行はAXONを指す。
// NEURON: A neuron refers to the DENDRITE / NEURON itself. If used in conjunction with a ROW then we mean the DENDRITE.
//////////////////////////////////////////////////////////////////////////////////

module TokenController #(
    parameter NUM_AXONS = 256,
    parameter NUM_NEURONS = 256,
    parameter NUM_WEIGHTS = 4,
    parameter FILENAME = "tc_000.mem"
)(
    input clk, 
    input rst,
    input tick,
    input [NUM_AXONS-1:0] axon_spikes, 
    input [NUM_AXONS-1:0] synapses, 
    input spike_in,
    input local_buffers_full,
    output reg error,
    output reg scheduler_set, 
    output reg scheduler_clr,
    output reg CSRAM_write,
    output reg [$clog2(NUM_NEURONS)-1:0] CSRAM_addr,
    output reg [$clog2(NUM_WEIGHTS)-1:0] neuron_instruction, 
    output reg spike_out,
    //output reg buffer_rst,
    output reg neuron_reg_en, 
    output reg next_neuron,
    output reg write_current_potential
);


    reg [$clog2(NUM_WEIGHTS)-1:0] neuron_instructions [0:NUM_AXONS-1];  // Stores all neuron instructions  すべてのニューロン命令を格納
    reg [3:0] state;                                                    // state of FSM
    reg [$clog2(NUM_AXONS):0] row_count;                                // Stores the axon that we are currently analyzing  現在分析中の軸索を保存する
    

    // Naming the possible states of the FSM      FSMの可能な状態に名前を付ける
    localparam IDLE = 0, SET_SCHED_INIT_CSRAM = 1, FIRST_AXON = 2, SPIKE_IN = 3, WRITE_CSRAM = 4, NEURON_CHECK = 5, CLR_SCHED = 6;
    
    // Report Token Controller error if we get a tick when we are not in the IDLE state 
    //IDLE状態でないときにティックが発生した場合、トークン・コントローラーのエラーを報告する。

    initial begin
        neuron_reg_en <= 0;
        write_current_potential <= 0;
        next_neuron <= 0;
        row_count <= 0;
        error <= 0;
        scheduler_set <= 0;
        scheduler_clr <= 0;
        CSRAM_write <= 0;
        CSRAM_addr <= 0;
        spike_out <= 0;
        //buffer_rst <= 0;
        neuron_instruction <= 0;
        $readmemb(FILENAME, neuron_instructions);//FILENAMEにはtc_xxx.memがはいる
    end
    
    /*
    Incrementing the row_count on the negative edge makes it so
    we won't try to increment row_count while we are using it
    to index into a word.
    負のエッジ(negedge clk)でrow_countをインクリメントすることで、row_countを
    使ってwordのインデックスを作成している最中にrow_countをインクリメントしようとすることがなくなる。
    */
    always@(negedge clk) begin
        if (rst) begin
            row_count <= 0;
        end
        
        case(state)
            SPIKE_IN: row_count <= row_count + 1;//0から255(AXON数)までインクリメント
            default: row_count <= 0;
        endcase
    end
    //デバッグ用
        wire axon_spike_cnt;
        wire synapses_cnt;
        assign axon_spike_cnt = axon_spikes[row_count];
        assign synapses_cnt = synapses[row_count];
    /*
    Token controller functionality is implemented as a FSM.
    On the positive edge it will send out control signals to
    the other modules and update its internal state.
    トークン・コントローラーの機能は、FSMとして実装されている。
    正のエッジ(posedge clk)で他のモジュールに制御信号を送り、内部状態を更新する。
    */
    always@(posedge clk)begin
        if(rst) begin
            scheduler_clr <= 0;
            state <= 0;
            error <= 0;
        end
        
        // Reporting the token controller error if receives a tick when not in IDLE state
        //IDLE状態でないときにティックを受信した場合のトークンコントローラエラーの報告
        if ((error == 0) && (state != IDLE) && tick)
            error <= 1;

        case(state)
            /*
            In this state the TC waits for the 'tick' signal
            この状態でTCは'tick'信号を待つ。
            */
            IDLE: begin//state0
                scheduler_clr <= 0;
                if (tick)
                    state <= SET_SCHED_INIT_CSRAM;
            end

            
            /*
            In this state the TC sends out a signal to set the scheduler and initialize the CSRAM. 
            scheduler_set increments the address counter in the scheduler so the scheduler reads 
            from the correct tick. Initializes the address counter in the CSRAM so
            it reads the data from the first neuron.
            この状態では、TC は<スケジューラを設定し、CSRAM を初期化する>信号を送信します。
            scheduler_setは、スケジューラが正しいティックから読み出すように、スケジューラのアドレス・カウンタ
            をインクリメントする。CSRAMのアドレス・カウンタを初期化し、最初のニューロンからデータを読み出すようにする。
            */
            SET_SCHED_INIT_CSRAM: begin//state1
                scheduler_set <= 1;//この信号をもらったスケジューラは、scheduler_SRAMの読み出しアドレスを更新する。SRAM内には、axon_spikeの情報が配列として格納
                CSRAM_addr <= 0;//CSRAMのアドレス・カウンタを初期化>>CSRAM[0]がsynapses信号となり、それをCRAMからもらう
                state <= FIRST_AXON;
            end
            

            /*
            This is the first of two states where we can process a spike. This state sets next_neuron
            high so the NB knows to use the current potential of the neuron as the starting point for
            the running sum. If there is no spike and synapse on the first axon, it sets 
            write_current_potential high which will write the current potential of the neuron in 
            the register of the neuron block. If there is a spike and synapse on the first axon,
            it integrates the spike into the potential.
            これはスパイクを処理できる2つの状態のうちの最初の状態である。このステートでは、next_neuron を high 
            に設定し、NB がニューロンの現在の電位をラ ニングサムの開始点として使用することを認識する。最初の軸索
            にスパイクとシナプスがなければ、write_current_potential を high(1) に設定し、ニューロンブロックのレジスタ
            にニューロンの現在の電位を書き込む。最初の軸索にスパイクとシナプスがあれば、スパイクを電位に積分する。

            多分、ここでの処理でやりたいのはニューロンブロック内のNPレジスタの初期化みたいなことだと思う
            最初の軸索入力とシナプスとの接続があれば、current_potentialに重みを加えた値をNPに入れる
            接続がなければ、そのままcurrent_potentialを入れる
            */
            FIRST_AXON: begin//state2
                scheduler_set <= 0;
                //軸索とニューロンが接続してるかを確認。してるならその軸索に関連付けられた重みがニューロンブロックで処理される
                if (axon_spikes[row_count] && synapses[row_count])//row_countは現在分析中の軸索
                    neuron_instruction <= neuron_instructions[row_count];//ニューロンブロック内MUXにて重みが選ばれる
                else
                    write_current_potential <= 1;//ニューロンブロックのレジスタにニューロンの現在の電位を書き込む?
                next_neuron <= 1;//このステートのながでここの行が一番重要だと思う．next_neuron を high に設定 >> neuronblock側でcurrent_potential(現在電位)を選択
                state <= SPIKE_IN;
                neuron_reg_en <= 1;//neuronblock内のレジスタに書き込み許可
            end
            

            /*
            Once we get past the first axon we know that the value in the register in
            the neuron block is valid. We can then set next_neuron and write_current_potential
            low so the neuron block will integrate spikes for the remaining axons.
            最初の軸索を越えれば、ニューロン・ブロックのレジスタの値が有効であることがわかる。next_neuron
            とwrite_current_potentialをLow(0)に設定し、ニューロン・ブロックが残りの軸索のスパイクを積分するようにします。
            ※積分するときはnext_neuronとwrite_current_potentialをLow(0)に設定

            多分、イメージだけどこのSPIKE_INていう状態はいっこのニューロンにたいする256個の軸索入力
            */
            SPIKE_IN: begin//state3
                next_neuron <= 0;//ここが1だとNPの更新ができない．ループならないので
                write_current_potential <= 0;

                /*neuron_reg_enはすこしスパイクっぽいような信号。row_countが256回回るまで論理積やる
                neuron_reg_enを受け取ったニューロンブロックはその信号に同期してNP(ff)の値を更新し続ける。
                その結果、ニューロンひとつ分の電位が更新される．多分，NPは現在の電位を格納してるレジスタ
                256回の論理積で最終的に更新された電位の値が閾値を上回ってたらスパイクをニューロンブロックから
                受け取るみたいな感じ．
                */
                neuron_reg_en <= axon_spikes[row_count] & synapses[row_count];
                neuron_instruction <= neuron_instructions[row_count];
                /*↑↑neuroninstructionは波形みたところ0,1,0,1,0,1,,,の連続 neuron_instructionの値自体は、
                外部ファイルから読みだしてる情報なのでニューラルネットワーク生成時にはじめから決まってる値かもしれない
                */

                
                // If we are on the NUM_AXONS-1 axon we are done processing the neuron
                //NUM_AXONS-1軸索上にいる場合、ニューロン一つ分の処理は終了。NUM_AXONS-1軸索上にいない場合はSPIKE_IN継続
                if (row_count == NUM_AXONS - 1)
                    state <= WRITE_CSRAM;
                else
                    state <= SPIKE_IN;//NUM_AXONS回、SPIKE_IN状態をループ
                
            end

            /*
            When we are done processing a single neuron setting CSRAM_write 
            high so we can write the updated potential back to the CSRAM.
            In this state we also check to see if the neuron spiked.
            If the neuron spiked but the local buffers in the router are 
            full, we wait in this state until they are not full. If the 
            buffers aren't full we output a spike and move onto the 
            next state.
             1つのニューロンの処理が終わると、CSRAM_write をハイに設定し、
             更新された電位を CSRAM に書き戻す。この状態で、ニューロンがスパイクしたかどうかもチェックする。
             ニューロンがスパイクしたが、ルーターのローカル・バッファが満杯である場合、満杯でなくなるまでこのステートで待機する。
             もし バッファ満杯でなければ、スパイクを出力して次の状態に移る。次の状態に移る。
            */
            WRITE_CSRAM: begin//state4
                neuron_reg_en <= 0;
                //buffer_rst <= 1;
                /*spike_in >> ニューロンブロック内にて，ニューロンがスパイクしたかどうか
                ただ、spike_inそのものはスパイク信号というかはトグル波っぽい。ニューロンブロックから現在のニューロンの"状態"が送られて
                きているという感じで、閾値に達してるなら状態ならずっと1、そうでないならずっと0という感じ。
                */
                if(spike_in) begin//from neuronblock　初期値1　トグル波
				    if(local_buffers_full) begin
				        spike_out <= 0;
				        state <= WRITE_CSRAM;//FlomLocalのバッファの空きがでるまでstate4をループさせて待機
				    end
				    else begin
				        spike_out <= 1;//to router spike_outが1になるのはspike_inが1のときではあるが、それに加えこのステイトにいないといけない。
                        CSRAM_write <= 1;//更新された電位を CSRAM に書き戻す
				        state <= NEURON_CHECK;
				    end
				end
				else begin
				    spike_out <= 0;
                    CSRAM_write <= 1;
				    state <= NEURON_CHECK;
				end
            end


            /*
            Setting spike low, if CSRAM has gone through every 
            neuron then we are done. If CSRAM still has neurons
            to go we go back to state 3 and process the next neuron
            スパイクを0に設定し、CSRAMがすべてのニューロンを使い切ったら終了だ。
            CSRAMにまだニューロンが残っていれば、状態3に戻り、次のニューロンを処理する。
            */
            NEURON_CHECK: begin//state5
                spike_out <= 0;
                //buffer_rst <= 0;
                CSRAM_write <= 0;
                if (CSRAM_addr == NUM_NEURONS - 1) begin
                   state <= CLR_SCHED;
                end
                else begin
                   CSRAM_addr <= CSRAM_addr + 1;
                   state <= FIRST_AXON;//状態3に戻り、次のニューロンを処理する
                end
            end

            /*
            Clearing the scheduler so it deletes all of the spikes that were
            just processed. Then goes back to IDLE state until we receive
            another tick.
            スケジューラーをクリアし、先ほど処理したスパイクをすべて削除する。
            その後、次のティックを受信するまでIDLE状態に戻る。
            */
            CLR_SCHED: begin//state6
                scheduler_clr <= 1;
				state <= IDLE;
            end

            default: begin
                state <= IDLE;
            end
        endcase
    end

endmodule
