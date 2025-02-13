package main

import "core:log"
import "core:mem"
import "core:os"
import "core:strings"
import "core:time"
import "core:net"

UPDATE_ENDPOINT :: "https://dynamicdns.park-your-domain.com/update?host=${host}&domain=${domain}&password=${password}&ip=${ip}"
SLEEP_TIME :: time.Minute * 15

Profile :: struct {
	host:     string,
	domain:   string,
	password: string,
}

Run_Error :: union {
	Process_Args_Error,
	Update_Routine_Error,
}

Update_Routine_Error :: union {
	net.Network_Error,
}

Process_Args_Error :: union {
	mem.Allocator_Error,
	Args_Error
}

Args_Error :: enum {
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
		defer de_init_tracking_alloc(&track_alloc)
	}

	profiles := init_profiles(os.args) or_return
	defer delete_slice(profiles)

	if err = update_routine(profiles); err != nil {
		log.info("setup_and_run - Exited without error")
		return
	}

	// handle errors
	error_message: string = ""
	switch _ in err {
	case Process_Args_Error: error_message = "setup_and_run - error processing arguments - %s"
	case Update_Routine_Error: error_message = "setup_and_run - error while looping - %s"
	}
	
	log.errorf(error_message, err)
	return
}

update_routine :: proc(profiles: []Profile, allocator := context.allocator) -> (err: Update_Routine_Error) {
	pool := mem.Dynamic_Arena{}
	mem.dynamic_arena_init(&pool)
	context.allocator = mem.dynamic_arena_allocator(&pool)
	defer mem.dynamic_arena_destroy(&pool)

	for {

	
		
		for params in profiles {
			defer mem.dynamic_arena_reset(&pool)
			
			
			// TODO: Implement routine
			
		}
		time.sleep(SLEEP_TIME)
	}
}

// Free with `delete_slice`
init_profiles :: proc(args: []string) -> (params_slice: []Profile, err: Process_Args_Error) {
	arg_len := len(args)

	if arg_len == 0 {
		err = .No_Args_Provided
		return
	}

	profiles_arr := make_dynamic_array_len_cap([dynamic]Profile, 0, arg_len) or_return
	defer if err != nil {
		delete_dynamic_array(profiles_arr)
	}

	for arg in args {
		param_strs := strings.split(arg[1:], ":") or_return
		if len(param_strs) != 3 {
			err = .Wrong_Params_Len
			return
		}
		params := Profile{param_strs[0], param_strs[1], param_strs[2]}
		append_elem(&profiles_arr, params)
	}
	params_slice = profiles_arr[:]
	return
}

de_init_tracking_alloc :: proc(track_alloc: ^mem.Tracking_Allocator) {
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

test_get_profiles :: proc(){}
