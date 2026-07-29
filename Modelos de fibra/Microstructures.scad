
/*
    M I C R O S T R U C T U R E S
    
    None/No-core:
        No parameters.
        
    Capillary:
        core diameter: inner (hollow) diameter
    
    Hexagonal:
        core diameter: defines the pitch (ms_core = 2*pitch)
        additional parameter 1: defines hole diameter (ap1 = hole_diameter)
        additional parameter 2: number of hexagonal rings
        additional parameter 3: Is there a central hole (0=no, anything else is yes)
        
    Suspended:
        core diameter: defines the core's diameter
        additional parameter 1: width for suspension
        additional parameter 2: number of suspensions
        additional parameter 3: cladding thickness
        
    Hollow_core:
        core diameter: hollow cavity diameter
        additional parameter 1: inner capillary thickness
        additional parameter 2: spacing between inner capillaries
        additional parameter 3: number of inner capillaries
        
    MNANF (Multi-Nested Antiresonant Nodeless Fibre):
        core diameter: hollow cavity diameter
        additional parameter 1: inner capillary thickness
        additional parameter 2: spacing between inner capillaries
        additional parameter 3: number of inner capillaries
        additional parameter 4: number of nested capillaries
        
*/


/*
    H E L P E R   F U N C T I O N S
*/

function _polygon_points(n, d) = [
    for(i=[0:n-1],
        t=360/n*i, r=d/2)
        [r*cos(t), r*sin(t)]
    ];
    
function _interpolated_polygon(n, d, n_interp) = [
        for(i=[0:n-1], r=d/2,
            t0=360/n*i, x0=r*cos(t0), y0=r*sin(t0),
            t1=360/n*(i+1), x1=r*cos(t1), y1=r*sin(t1))
        
        each [
            [x0, y0],
            for(j=[1:n_interp],
                a=j/(n_interp+1), b=(n_interp+1-j)/(n_interp+1),
                x=a*x0+b*x1, y=a*y0+b*y1)
                
                [x, y]
            ]
    ];


module copy_and_rotate(n){
    for(i=[0:n-1], t=360/n*i){
        rotate([0,0,t])
            children();
    }
}


module _tangential_circles(d_list, thickness){
    max_r = max(d_list)/2;
    for(d=d_list, r=d/2)
        translate([max_r-r, 0, 0])
        difference(){
            circle(d=d);
            circle(r=r-thickness);
        }
}

/*
    S T R U C T U R E   M O D U L E S
*/

module _capillary(d, core){
    difference(){
        circle(d=d);
        circle(d=core);
    }
}

module _suspended_core(d, core, w, n, t){
    union(){
        // Outer circle (cladding)
        difference(){
            circle(d=d);
            circle(d=d-2*t);
        }
        
        // Core
        circle(d=core);
        
        copy_and_rotate(n)
            translate([d/4,0,0])
            square([d/2, w], center=true);
        
    }
}


module _hexagonal(d, core_d, hole_d, n_rings, ms_ap3){
    pitch = (core_d+hole_d)/2;
    central_hole = ms_ap3==0 ? false : true;
    difference(){
        // Solid preform
        circle(d=d);
        
        // Central hole
        if(central_hole)
            circle(d=hole_d);
        
        // Microstructure holes
        for(ring=[1:n_rings], r=pitch*ring)
        for(p=_interpolated_polygon(6, 2*r, ring-1))
            translate([p.x, p.y, 0])
                circle(d=hole_d);
    }
}


module _hollow_core(d, core, thick, spacing, n, excentricity=1.0){
    delta_t = 360/n;
    r_ext = core/2;
    aux_sqrt = sqrt(2-2*cos(delta_t));
    r_int_ext = ( r_ext * aux_sqrt - spacing ) / (2 + aux_sqrt);
    r_int_int = r_int_ext - thick;
    
    exc1 = excentricity;
    exc2 = (r_int_ext*exc1 - thick) / r_int_int;
    
    echo("Rint:", r_int_int);
    
    union(){
        // Outer circle (cladding)
        difference(){
            circle(d=d);
            circle(d=core);
        }
        
        intersection(){
            circle(d=d);
        
            copy_and_rotate(n){
                translate([(r_ext-r_int_ext)*exc1,0,0])
                difference(){
                    scale([exc1,1,1])
                    circle(r=r_int_ext);
                    
                    scale([exc2,1,1])
                    circle(r=r_int_int);
                }
            }
        }
    }
}


module _mnanf(d, core, thick, spacing, n, m){
    delta_t = 360/n;
    r_ext = core/2;
    aux_sqrt = sqrt(2-2*cos(delta_t));
    r_int_ext = ( r_ext * aux_sqrt - spacing ) / (2 + aux_sqrt);
    r_int_int = r_int_ext - thick;
    
    echo("Rint:", r_int_int);
    
    d_list = [
        for(i=[1:m+1], di=2*r_int_ext*i/(m+1))
            di
    ];
    
    union(){
        // Outer circle (cladding)
        difference(){
            circle(d=d);
            circle(d=core);
        }
        
        copy_and_rotate(n){
            translate([r_ext-r_int_int,0,0])
            _tangential_circles(d_list, thick);
        }
    }
}


/*
    P R E S S U R I Z A T I O N   M O D U L E S
*/

module _pressure_hollow_core(d, core, thick, spacing, n, excentricity=1.0){
    delta_t = 360/n;
    r_ext = core/2;
    aux_sqrt = sqrt(2-2*cos(delta_t));
    r_int_ext = ( r_ext * aux_sqrt - spacing ) / (2 + aux_sqrt);
    r_int_int = r_int_ext - thick;
    
    //excentricity for the EXTERIOR of inner capillaries
    exc1 = excentricity;
    //excentricity for the INTERIOR of inner capillaries
    exc2 = (r_int_ext*exc1 - thick) / r_int_int;
    
    difference(){
        // Outer circle (cladding)
        circle(d=d);
    
        
        intersection(){
            circle(d=core);
        
            copy_and_rotate(n){
                translate([(r_ext-r_int_ext)*exc1,0,0])
                scale([exc2,1,1])
                    circle(r=r_int_int);
            }
        }
    }
}



module _pressure_MNANF(d, core, thick, spacing, n, m){
    delta_t = 360/n;
    r_ext = core/2;
    aux_sqrt = sqrt(2-2*cos(delta_t));
    r_int_ext = ( r_ext * aux_sqrt - spacing ) / (2 + aux_sqrt);
    r_int_int = r_int_ext - thick;
    
    d_list = [
        for(i=[1:m+1], di=2*r_int_ext*i/(m+1))
            di
    ];
    
    difference(){
        // Outer circle (cladding)
        circle(d=d);
        
        intersection(){
            circle(d=core);
            copy_and_rotate(n){
                translate([r_ext-r_int_int,0,0])
                difference(){
                    circle(r=r_int_int);
                    _tangential_circles(d_list, thick);
                }
            }
        }
    }
}


/*
    E X P O R T   M O D U L E S
*/

module _microstructure(ms_type,preform_diameter,ms_core,ms_ap1,ms_ap2,ms_ap3,ms_ap4=0) {

    if(ms_type == "None" || ms_type == "No-core"){
        circle(d=preform_diameter);
    }
    else if(ms_type == "Capillary"){
        _capillary(preform_diameter, ms_core);
    }
    else if(ms_type == "Suspended"){
        _suspended_core(preform_diameter, ms_core, ms_ap1, ms_ap2, ms_ap3);
    }
    else if(ms_type == "Hexagonal"){
        _hexagonal(preform_diameter, ms_core, ms_ap1, ms_ap2, ms_ap3);
    }
    else if(ms_type == "Hollow_core"){
        _hollow_core(preform_diameter, ms_core, ms_ap1, ms_ap2, ms_ap3, ms_ap4);
    }
    else if(ms_type == "MNANF"){
        _mnanf(preform_diameter, ms_core, ms_ap1, ms_ap2, ms_ap3, ms_ap4);
    }
}


module _pressure_lid(ms_type,preform_diameter,ms_core,ms_ap1,ms_ap2,ms_ap3,ms_ap4=0){

    if(ms_type == "None" || ms_type == "No-core"){
        circle(d=preform_diameter);
    }
    else if(ms_type == "Capillary"){
        _capillary(preform_diameter, ms_core);
    }
    else if(ms_type == "Suspended"){
        _suspended_core(preform_diameter, ms_core, ms_ap1, ms_ap2, ms_ap3);
    }
    else if(ms_type == "Hexagonal"){
        _hexagonal(preform_diameter, ms_core, ms_ap1, ms_ap2, ms_ap3);
    }
    else if(ms_type == "Hollow_core"){
        _pressure_hollow_core(preform_diameter, ms_core, ms_ap1, ms_ap2, ms_ap3, ms_ap4);
    }
    else if(ms_type == "MNANF"){
        _pressure_MNANF(preform_diameter, ms_core, ms_ap1, ms_ap2, ms_ap3, ms_ap4);
        //assert(false, "MNANF pressure lid not implemented");
    }


}


//linear_extrude(h=10)
//_pressure_hollow_core(d=70, core=55, thick=2, spacing=1, n=5);