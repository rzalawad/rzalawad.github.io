num_drives = 9;

inch_to_mm = 25.4;

hdd_width = 4 * inch_to_mm;
hdd_length = 5.8 * inch_to_mm;
hdd_height = 0.8 * inch_to_mm;

cage_margin = 10;


// hdds will be mounted top down
hdd_cage_width = hdd_width + cage_margin;
hdd_cage_length = hdd_length * 0.2;// since we want to pass through and merge with bottom
hdd_cage_height = hdd_height + cage_margin;



box_margin = 60;
box_length = num_drives * hdd_cage_height + box_margin;
box_width = 1.5 * hdd_cage_width;
box_height = 160;

box_thickness = 10;


fan_diameter = 120;

M4_DIAMETER = 4.2;
M5_DIAMETER = 5.2;

inter_screw_distance = 105;// for 120mm fan. see: 120mm fan diagram on google
screw_hold_diameter = M4_DIAMETER;

// Module for a basic through hole
module screw_hole(pos_fan, center = true) {
  union() {
    //translate([-inter_screw_distance/2, 0, -inter_screw_distance/2])


    translate([-inter_screw_distance / 2, 0, -inter_screw_distance / 2])
      translate(pos_fan)
        rotate([90, 0, 0])
          cylinder(d = screw_hold_diameter, h = box_width * 2, center = center, $fn = 32);


    translate([inter_screw_distance / 2, 0, inter_screw_distance / 2])
      translate(pos_fan)
        rotate([90, 0, 0])
          cylinder(d = screw_hold_diameter, h = box_width * 2, center = center, $fn = 32);

    translate([-inter_screw_distance / 2, 0, inter_screw_distance / 2])
      translate(pos_fan)
        rotate([90, 0, 0])
          cylinder(d = screw_hold_diameter, h = box_width * 2, center = center, $fn = 32);
    translate([inter_screw_distance / 2, 0, -inter_screw_distance / 2])
      translate(pos_fan)
        rotate([90, 0, 0])
          cylinder(d = screw_hold_diameter, h = box_width * 2, center = center, $fn = 32);
  }
}


module main_box() {
  group() {
    difference() {
      cube([box_length, box_width, box_height], center = true);

      translate([0, 0, box_thickness]) {
        cube([box_length - box_thickness, box_width - box_thickness, box_height], center = true);
      }
      ;

      // fan holes
      translate([box_length / 4, 0, 10])
        rotate([90, 0, 0])
          cylinder(r = fan_diameter / 2, h = box_width * 2, center = true, $fn = 100);
      translate([-box_length / 4, 0, 10])
        rotate([90, 0, 0])
          cylinder(r = fan_diameter / 2, h = box_width * 2, center = true, $fn = 100);

          // screw holes for each fan
      // left fan
      screw_hole([-box_length / 4, 0, 10], true);

      // right fan
      screw_hole([box_length / 4, 0, 10], true);

      // cable hole
      translate([0, 0, 70])
        cube([box_length + 20, box_width / 3, box_height / 2], center = true);

    }
    translate([box_length / 4, ((box_width - (box_thickness / 2)) / 2), 10])
      rotate([90, 0, 0])
        mesh_fan();
    translate([-box_length / 4, ((box_width - (box_thickness / 2)) / 2), 10])
      rotate([90, 0, 0])
        mesh_fan();
    translate([box_length / 4, -((box_width - (box_thickness / 2)) / 2), 10])
      rotate([90, 0, 0])
        mesh_fan();
    translate([-box_length / 4, -((box_width - (box_thickness / 2)) / 2), 10])
      rotate([90, 0, 0])
        mesh_fan();



  }
}


grid_spacing = 30;// Space between grid lines
angle = 45;
mesh_thickness = 2;
module mesh_fan() {

  intersection() {
    // Cylinder to clip the mesh
    cylinder(h = box_width * 2, d = fan_diameter, center = true, $fn = 100);

    // Create diagonal grid
    union() {
      // First set of diagonal lines
      for(i = [-fan_diameter:grid_spacing:fan_diameter]) {
        translate([i, 0, 0])
          rotate([0, 0, angle])
            cube([mesh_thickness, fan_diameter * 2, box_thickness / 2], center = true);
      }

      // Second set of diagonal lines (perpendicular to first set)
      for(i = [-fan_diameter:grid_spacing:fan_diameter]) {
        translate([i, 0, 0])
          rotate([0, 0, -angle])
            cube([mesh_thickness, fan_diameter * 2, box_thickness / 2], center = true);
      }

    }
  }
}

//hdd_z_shift = -((box_height / 2) - (hdd_cage_height / 2));
hdd_z_shift = -((box_height / 2) - (hdd_cage_length/2) - box_thickness/2);

module create_drive(drive_idx) {
  translate([drive_idx * hdd_cage_height - ((num_drives * hdd_cage_height) / 2), 0, hdd_z_shift]) {
    difference() {
      cube([hdd_cage_height, hdd_cage_width, hdd_cage_length], center = true);
      cube([hdd_height, hdd_width, hdd_length], center = true);
    }
  }
}

group() {
  for(i = [0:num_drives]) {
    create_drive(i);
  }

  main_box();

}
