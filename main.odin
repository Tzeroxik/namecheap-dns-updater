package main

import "core:log"
import "core:mem"
import "core:os"
import "core:strings"
import "core:time"
import "core:net"
import "core:testing"
import "core:fmt"

UPDATE_ENDPOINT :: "https://dynamicdns.park-your-domain.com/update?host=${host}&domain=${domain}&password=${password}&ip=${ip}"
SLEEP_TIME :: time.Minute * 15

Profile :: struct {
	host:     string,
	domain:   string,
	api_key: string,
}

Run_Error :: union {
	Init_Profile_Error,
	Update_Routine_Error,
	mem.Allocator_Error,
}

Update_Routine_Error :: union {
	net.Network_Error,
}

Init_Profile_Error :: union {
	mem.Allocator_Error,
	Create_Profile_Error_Type
}

Create_Profile_Error_Type :: enum {
	Wrong_Params_Len,
	No_Args_Provided,
}

main :: proc() {
	if setup_and_run() != nil {
		os.exit(-1)
	}
}

setup_and_run :: proc(allocator := context.allocator) -> (err: Run_Error) {
	logger := log.create_console_logger()
	context.logger = logger
	defer log.destroy_console_logger(logger)

	// setup allocator
	when ODIN_DEBUG {
		track_alloc: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track_alloc, context.allocator)
		context.allocator = mem.tracking_allocator(&track_alloc)
		defer delete_tracking_alloc(&track_alloc)
	}
	
	if len(os.args) < 2 {
		log.error("Invalid os.args size")
		return
	}

	profiles := init_profiles(os.args[1:]) or_return
	defer delete_profiles(profiles)

	if err = update_routine(profiles); err != nil {
		log.info("setup_and_run - Exited without error")
		return
	}

	// handle errors
	error_message: string = ""
	switch _ in err {
	case Init_Profile_Error: error_message = "error processing arguments - %s"
	case Update_Routine_Error: error_message = "error while looping - %s"
	case mem.Allocator_Error: error_message = "error while allocating - %s"
	}
	
	log.errorf(error_message, err)
	return
}

update_routine :: proc(profiles: []Profile, allocator := context.allocator) -> (err: Update_Routine_Error) {
	pool := mem.Dynamic_Arena{}
	mem.dynamic_arena_init(&pool)
	context.allocator = mem.dynamic_arena_allocator(&pool)
	defer mem.dynamic_arena_destroy(&pool)

	iteration := 0
	for {
		log.infof("Starting iteration %d", iteration)
		for params in profiles {
			defer mem.dynamic_arena_reset(&pool)
			
			
			// TODO: Implement routine
			
		}
		time.sleep(SLEEP_TIME)
		iteration += 1
	}
}

// free with `delete_profile`
init_profile:: proc(arg: string) -> (profile: Profile, error: Init_Profile_Error) {
	param_strs := strings.split(arg, ":") or_return
	defer delete_slice(param_strs)

	if len(param_strs) != 3 {
		error = .Wrong_Params_Len
		return
	}

	profile = Profile{
		strings.clone_from(param_strs[0]) or_return, 
		strings.clone_from(param_strs[1]) or_return, 
		strings.clone_from(param_strs[2]) or_return
	}
	return
}

delete_profile :: proc(profile: Profile) -> (err: mem.Allocator_Error) {
	delete_string(profile.host) or_return
	delete_string(profile.domain) or_return
	delete_string(profile.api_key) or_return
	return
}

// Free with `delete_profiles`
init_profiles :: proc(args: []string, allocator := context.allocator) -> (profiles: []Profile, error: Init_Profile_Error) {
	context.allocator = allocator
	arg_len := len(args)

	if arg_len == 0 {
		error = .No_Args_Provided
		return
	}

	profiles_arr := make_dynamic_array_len_cap([dynamic]Profile, 0, arg_len) or_return
	defer if error != nil {
		delete_dynamic_array(profiles_arr)
	}

	for arg in args {
		profile := init_profile(arg) or_return
		append_elem(&profiles_arr, profile)
	}

	profiles = profiles_arr[:]
	return
}

delete_profiles :: proc(profiles: []Profile, allocator:= context.allocator) -> (err: mem.Allocator_Error) {
	context.allocator = allocator;
	for profile in profiles {
		delete_profile(profile) or_return
	}
	return delete_slice(profiles)
}

delete_tracking_alloc :: proc(track_alloc: ^mem.Tracking_Allocator) {
	if len(track_alloc.allocation_map) > 0 {
		log.errorf("=== %v allocations not freed: ===\n", len(track_alloc.allocation_map))
		for _, entry in track_alloc.allocation_map {
			log.errorf("- %v bytes @ %v\n", entry.size, entry.location)
		}
	}
	if len(track_alloc.bad_free_array) > 0 {
		log.errorf("=== %v incorrect frees: ===\n", len(track_alloc.bad_free_array))
		for entry in track_alloc.bad_free_array {
			log.errorf("- %p @ %v\n", entry.memory, entry.location)
		}
	}
	mem.tracking_allocator_destroy(track_alloc)
}

@(test)
test_init_profile :: proc(t: ^testing.T){
	
	profile := []string { "@:example.com:1kdsaçdksakdçaslçdkças0238902i0" }
	profiles, err := init_profiles(profile)
	defer delete_profiles(profiles)

	if err != nil {
		fmt.println(err)
		testing.fail_now(t,"init_profiles failed")
	}

	actual_profile := profiles[0]
	testing.expect_value(t,actual_profile.host , "@")
	testing.expect_value(t,actual_profile.domain,"example.com")
	testing.expect_value(t,actual_profile.api_key,"1kdsaçdksakdçaslçdkças0238902i0")
}
