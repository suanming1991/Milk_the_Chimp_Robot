puts "we are gonna start!!!!!!!!!!!!!!!!!!"
puts "This is Zexious!!!"

set dir [pwd]
#set contents [glob -directory $dir *_tb.v]
set contents [glob -directory $dir -tails *_tb.v]
set index 1;
 puts "Directory contents are:"
    foreach item $contents {
    	
        puts "$index. $item"
        set index [expr {$index + 1}]
        }
puts "Select which testbench to compile:"
set userInput [gets stdin]
#set userInputConverted [expr $userInput]

puts "get the user input is $userInput"
set tbToBeSimulated [lindex $contents [expr {$userInput}]]
puts "tb is $tbToBeSimulated"
set parseIndex [string first . $tbToBeSimulated]
puts "parseIndex is $parseIndex"
string range $tbToBeSimulated 0 [expr {$parseIndex-1}]
puts "parsed text is $tbToBeSimulated"

puts "start compiling..."
project compileall
puts "start simulation..."
vsim -gui work.motor_cntrl_tb
puts "adding signals..."
add wave -position insertpoint sim:/motor_cntrl_tb/*
puts "running all..."
run -all