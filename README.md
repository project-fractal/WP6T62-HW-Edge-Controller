# WP6-T02 Hardware Edge Controller


## Description

The Hardware Edge Controller, is responsible to, control the injection time of the NoC-based multi-core platform using precomputed, schedule which is computed offline. The H/W Edge controller also has an on-off Chip gateway, that, permits communication between on/off-chip Domaine. The communication between multiple nodes is done by TSN. The NoC Gateway, is an extension of the NI, with time-triggered and adaptability capability. That allows the GW, to send messages according to a predefined schedule, and allows the Gateway, to switch from one to another schedule whenever a context event occurs within the hierarchical systems. The main job of GW is to receive the messages from the NoC, converted them with an Ethernet frame, and send them to the off-chip communication through TSN.

## Objectives
* Schedule the communication and computation within the systems.
* Deterministic communication within hierarchical systems.
* Adaptability features, allow the on-chip and off-chip network to switch schedules when a context event occurs (such as permanent failures within an NoC).
## Prerequisites

H/W Edge controller, is an IP coded in VHDL and Verilog:
* Xilix Vitis version 2021.x
* Xilinx Vivado suite version 2021.x

## Installation and usage 

The H/W Edge controller is a part of the ATTNoC code, that include NoC-Gateway Network Interface , and Global Time Base. 
An example to setup the ATTNoC code can be seen in this link https://github.com/project-fractal/WP4-T43-004-ATTNoC
