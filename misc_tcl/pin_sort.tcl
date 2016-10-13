#XILINX INC
#sort the pin assignment XDC by order of pad name
#procedure
#  1) read design by planAhead
#  2) export xdc by write_xdc in planAhead
#  3) source pin_sort.tcl in Vivado
#  4) run cmd 
#      pin_sort ifilename ofilename ononpin_filename tabfilename
#      > ifilename: the xdc file exported by planAhead
#      > ofilename: the new xdc file sorting the pin related constraints by pad name
#      > ononpin_filename: the xdc file which comment the pin assignment out and keep other constraints.
#      > tabfilename: the pin table contains all properties set by xdc file. sorted by pad name.


proc pin_sort {ifilename ofilename ononpin_filename tabfilename} {
  #set ifilename pin_assignment.xdc;
  #set ofilename pin_out.txt;
  #set tabfilename  pin_tab.txt
  puts " opening files $ifilename, $ofilename, $ononpin_filename, $tabfilename";
  set fin [open $ifilename r];
  set fout [open $ofilename w];
  set fother [ open $ononpin_filename w];
  set ftab [open $tabfilename w];
  #set pattern1 "^\S*set_property.*\[get_ports\S+\s+\]";
  while { [gets $fin line] >=0 } {
    # puts $line;
    if { [regexp {^\s*set_property\s+(\S+)\s+(\S+)\s+\[get_ports\s+(.+)\]} $line match property_name property_value pad_name] >0 }  {
        #puts "$pad_name,$property_name,$property_value\n";#debug puts value to check
        array set $property_name [list $pad_name $property_value];
        lappend property_list $property_name;
        puts $fother "\#$line";
    } else {
       puts $fother "$line";
    }
    
  }
  #- while gets $fin

  puts "planAhead XDC reading done";

  set property_list [lsort -unique $property_list];

 if {[set pin_idx [lsearch $property_list PACKAGE_PIN]] >=0} {
         set property_list [lreplace $property_list $pin_idx $pin_idx];
 } else {
         puts "ERROR: property PACKAGE_PIN doesn't exist!!!";
 }


  #export pin table and new pin assigment xdc
 set tab_line PACKAGE_PIN;
 foreach pro_element $property_list {
	 set tab_line "$tab_line,$pro_element";
 }
 puts $ftab "$tab_line";
 puts $ftab [string repeat "-" 50];
 foreach pad_name [lsort [array name PACKAGE_PIN]] {
         set tab_line "$pad_name,$PACKAGE_PIN($pad_name)";
         puts $fout "set_property PACKAGE_PIN $PACKAGE_PIN($pad_name) \[get_ports $pad_name\]";
         foreach pro_element $property_list {
       	  if {[llength [array get $pro_element $pad_name]]>0} {
		  #puts "DEBUG: $pro_element: $pad_name-> [lindex [array get $pro_element $pad_name] 1] length: [llength [array get $pro_element $pad_name]] !!\n";

       		  set tab_line "$tab_line,[lindex [array get $pro_element $pad_name] 1]";
       		  puts $fout "set_property $pro_element [lindex [array get $pro_element $pad_name] 1] \[get_ports $pad_name\]";
       	  } else {
		  #puts "no value: $pad_name, $pro_element\n";
		  set tab_line "$tab_line, ";
	  }
         }
       	  puts $ftab "$tab_line ";
	  puts $fout "";
 }
 close $fin;
 close $fout;
 close $fother;
 close $ftab;
# array get $property_name;
}
