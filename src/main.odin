package main

import "core:log"
import "core:mem"
import "core:os"
import "core:strings"

ENDPOINT :: "https://dynamicdns.park-your-domain.com/update?host=${host}&domain=${domain}&password=${password}&ip=${ip}"

Params :: struct {
	host:     string,
	domain:   string,
	password: string,
}

Run_Error :: union {
	Process_Args_Error,
	Update_Routine_Error,
}

Update_Routine_Error :: union {
	int, // TODO
}

Process_Args_Error :: union {
	mem.Allocator_Error,
	Args_Error,
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

	err = set_up_and_run_routine()

	// handle errors
	error_message: string = ""
	switch _ in err {
	case Process_Args_Error:
		error_message = "error processing arguments %s"
	case Update_Routine_Error:
		error_message = "error while looping %s"
	}

	log.errorf(error_message, err)
	return
}

set_up_and_run_routine :: proc(allocator := context.allocator) -> (err: Run_Error) {
	context.allocator = allocator
	params_slice := init_params_slice(os.args) or_return
	defer delete_slice(params_slice)
	update_routine(params_slice) or_return
	return
}

update_routine :: proc(params_slice: []Params) -> (err: Update_Routine_Error) {
	for {
		for params in params_slice {
			// TODO: Implement routine
		}
	}
}

// Free with `delete_slice`
init_params_slice :: proc(args: []string) -> (params_slice: []Params, err: Process_Args_Error) {
	arg_len := len(args)

	if arg_len == 0 {
		err = .No_Args_Provided
		return
	}

	param_arr := make_dynamic_array_len_cap([dynamic]Params, 0, arg_len) or_return
	defer if err != nil {
		delete_dynamic_array(param_arr)
	}

	for arg in args {
		param_strs := strings.split(arg[1:], ":") or_return
		if len(param_strs) != 3 {
			err = .Wrong_Params_Len
			return
		}
		params := Params{param_strs[0], param_strs[1], param_strs[2]}
		append_elem(&param_arr, params)
	}
	params_slice = param_arr[:]
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
