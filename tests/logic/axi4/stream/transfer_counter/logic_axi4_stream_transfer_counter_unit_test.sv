/* Copyright 2018 Tymoteusz Blazejczyk
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

`include "svunit_defines.svh"

module logic_axi4_stream_transfer_counter_unit_test;
    import svunit_pkg::svunit_testcase;

    string name = "logic_axi4_stream_transfer_counter_unit_test";
    svunit_testcase svunit_ut;

    parameter TDATA_BYTES = 4;
    parameter COUNTER_MAX = 256;

    typedef bit [TDATA_BYTES-1:0][7:0] tdata_t;

    typedef byte data_t[];

    function automatic data_t create_data(int length);
        data_t data = new [length];
        foreach (data[i]) begin
            data[i] = $urandom;
        end
        return data;
    endfunction

    logic aclk = 0;
    logic areset_n = 0;

    initial forever #1 aclk = ~aclk;

    logic_axi4_stream_if #(
        .TDATA_BYTES(TDATA_BYTES)
    ) rx (.*);

    logic_axi4_stream_if #(
        .TDATA_BYTES(TDATA_BYTES)
    ) tx (.*);

    logic_axi4_stream_if #(
        .TDATA_BYTES(TDATA_BYTES)
    ) counter (.*);

    logic_axi4_stream_transfer_counter #(
        .COUNTER_MAX(COUNTER_MAX),
        .TDATA_BYTES(TDATA_BYTES)
    )
    dut (
        .monitor_rx(rx),
        .monitor_tx(tx),
        .tx(counter),
        .*
    );

    logic_axi4_stream_queue #(
        .CAPACITY(COUNTER_MAX),
        .TDATA_BYTES(TDATA_BYTES)
    )
    queue_unit (
        .*
    );

    function void build();
        svunit_ut = new (name);
    endfunction

    task setup();
        svunit_ut.setup();

        areset_n = 0;
        counter.cb_tx.tready <= '0;
        @(rx.cb_rx);

        areset_n = 1;
        counter.cb_tx.tready <= '1;
        @(rx.cb_rx);
    endtask

    task teardown();
        svunit_ut.teardown();

        areset_n = 0;
        counter.cb_tx.tready <= '0;
    endtask

`SVUNIT_TESTS_BEGIN

`SVTEST(short)
    byte data[] = new [COUNTER_MAX * TDATA_BYTES];
    byte captured[];
    byte value[];

    foreach (data[i]) begin
        data[i] = $urandom;
    end

    rx.cb_write(data);

    @(counter.cb_rx);
    counter.cb_read(value);
    counter.cb_tx.tready <= '1;

    `FAIL_UNLESS_EQUAL(tdata_t'({<<8{value}}), COUNTER_MAX)

    tx.cb_read(captured);

    @(counter.cb_rx);
    counter.cb_read(value);
    `FAIL_UNLESS_EQUAL(tdata_t'({<<8{value}}), 0)
`SVTEST_END

`SVTEST(slow_write)
    byte data[] = new [COUNTER_MAX * TDATA_BYTES];
    byte captured[];
    byte value[];

    foreach (data[i]) begin
        data[i] = $urandom;
    end

    rx.cb_write(data, 0, 0, 3, 0);

    @(counter.cb_rx);
    counter.cb_read(value);
    counter.cb_tx.tready <= '1;

    `FAIL_UNLESS_EQUAL(tdata_t'({<<8{value}}), COUNTER_MAX)

    tx.cb_read(captured);

    @(counter.cb_rx);
    counter.cb_read(value);
    `FAIL_UNLESS_EQUAL(tdata_t'({<<8{value}}), 0)
`SVTEST_END

`SVTEST(slow_read)
    byte data[] = new [COUNTER_MAX * TDATA_BYTES];
    byte captured[];
    byte value[];

    foreach (data[i]) begin
        data[i] = $urandom;
    end

    rx.cb_write(data);

    @(counter.cb_rx);
    counter.cb_read(value);
    counter.cb_tx.tready <= '1;

    `FAIL_UNLESS_EQUAL(tdata_t'({<<8{value}}), COUNTER_MAX)

    tx.cb_read(captured, 0, 0, 3, 0);

    @(counter.cb_rx);
    counter.cb_read(value);
    `FAIL_UNLESS_EQUAL(tdata_t'({<<8{value}}), 0)
`SVTEST_END

`SVTEST(slow_read_write)
    byte data[] = new [COUNTER_MAX * TDATA_BYTES];
    byte captured[];
    byte value[];

    foreach (data[i]) begin
        data[i] = $urandom;
    end

    rx.cb_write(data, 0, 0, 3, 0);

    @(counter.cb_rx);
    counter.cb_read(value);
    counter.cb_tx.tready <= '1;

    `FAIL_UNLESS_EQUAL(tdata_t'({<<8{value}}), COUNTER_MAX)

    tx.cb_read(captured, 0, 0, 3, 0);

    @(counter.cb_rx);
    counter.cb_read(value);
    `FAIL_UNLESS_EQUAL(tdata_t'({<<8{value}}), 0)
`SVTEST_END

`SVTEST(write_data)
    byte data[];
    byte captured[];
    byte value[];

    data = create_data(13 * TDATA_BYTES);
    rx.cb_write(data);

    @(counter.cb_rx);
    counter.cb_read(value);
    counter.cb_tx.tready <= '1;

    `FAIL_UNLESS_EQUAL(tdata_t'({<<8{value}}), 13)

    data = create_data(7 * TDATA_BYTES);
    rx.cb_write(data);

    @(counter.cb_rx);
    counter.cb_read(value);
    counter.cb_tx.tready <= '1;

    `FAIL_UNLESS_EQUAL(tdata_t'({<<8{value}}), 20)

    data = create_data(26 * TDATA_BYTES);
    rx.cb_write(data);

    @(counter.cb_rx);
    counter.cb_read(value);
    counter.cb_tx.tready <= '1;

    `FAIL_UNLESS_EQUAL(tdata_t'({<<8{value}}), 46)
`SVTEST_END

`SVUNIT_TESTS_END

endmodule
