// *************************************************************************
//
// Copyright 2020 Xilinx, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// *************************************************************************
`ifndef _QDMA_C2H_MONITOR_
`define _QDMA_C2H_MONITOR_

class qdma_c2h_monitor#(TDATA_W) extends uvm_monitor;
  `uvm_component_param_utils(qdma_c2h_monitor#(TDATA_W))

  typedef qdma_c2h_transaction seq_item_t;

  virtual qdma_c2h_if#(TDATA_W) _if;
  uvm_analysis_port#(seq_item_t) analysis_port;

  function new(string name="qdma_c2h_monitor", uvm_component parent=null);
    super.new(name, parent);
  endfunction: new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    analysis_port = new("analysis_port", this);
  endfunction: build_phase

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item_t item = seq_item_t::type_id::create("item", this);
      do_monitor(item);
    end
  endtask: run_phase

  function void do_stream_in(seq_item_t item);
    byte tdata[] = new[TDATA_W / 8];
    int  mty;
    bit  tlast;

    tdata = {<<8{_if.tdata}};
    mty   = _if.mty;
    tlast = _if.tlast;

    // foreach (tdata[i]) begin
    //   if (_if.dpar[i] != ~(^tdata[i])) begin
    //     `uvm_warning(get_name(), $sformatf("found parity mismatch: bit %d", i));
    //   end
    // end

    item.do_stream_in(tdata, mty, tlast);
  endfunction: do_stream_in

  task do_monitor(seq_item_t item);
    @(posedge _if.aclk iff _if.tvalid);
    item.qid     = _if.ctrl_qid;
    item.port_id = _if.ctrl_port_id;
    item.len     = _if.ctrl_len;
    analysis_port.write(item);

    if (_if.tready) begin
      do_stream_in(item);
    end

    while (~_if.tlast) begin
      @(posedge _if.aclk iff (_if.tvalid && _if.tready));
      do_stream_in(item);
    end

    analysis_port.write(item);
  endtask: do_monitor

endclass: qdma_c2h_monitor

`endif
