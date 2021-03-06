# __precompile__()

"""
MADS: Model Analysis & Decision Support in Julia (Mads.jl v1.0) 2017

module DocumentFunction

http://mads.lanl.gov
https://github.com/madsjulia

Licensing: GPLv3: http://www.gnu.org/licenses/gpl-3.0.html
"""
module DocumentFunction

"""
Redirect STDOUT to a reader
"""
function stdoutcaptureon()
	global outputoriginal = STDOUT;
	(outR, outW) = redirect_stdout();
	global outputread = outR;
	global outputwrite = outW;
	global outputreader = @async readstring(outputread);
end

"""
Restore STDOUT
"""
function stdoutcaptureoff()
	redirect_stdout(outputoriginal);
	close(outputwrite);
	output = wait(outputreader);
	close(outputread);
	return output
end

function documentfunction(f::Function; location::Bool=true, maintext::String="", argtext::Dict=Dict(), keytext::Dict=Dict())
	modulename = Base.function_module(f)
	stdoutcaptureon()
	if maintext != ""
		println("**$(f)**\n")
		println("$(maintext)\n")
	end
	m = methods(f)
	ms = convert(Array{String, 1}, strip.(split(string(m.mt), "\n"))[2:end])
	nm = length(ms)
	if nm == 0
		println("No methods\n")
	else
		println("Methods")
		for i = 1:nm
			s = strip.(split(ms[i], " at "))
			if location
				println(" - `$modulename.$(s[1])` : $(s[2])")
			else
				println(" - `$modulename.$(s[1])`")
			end
		end
		a = getfunctionarguments(f, ms)
		l = length(a)
		if l > 0
			println("Arguments")
			for i = 1:l
				arg = strip(string(a[i]))
				print(" - `$(arg)`")
				if contains(arg, "::")
					arg = split(arg, "::")[1]
				end
				if haskey(argtext, arg)
					println(" : $(argtext[arg])")
				else
					println("")
				end
			end
		end
		a = getfunctionkeywords(f, ms)
		l = length(a)
		if l > 0
			println("Keywords")
			for i = 1:l
				key = strip(string(a[i]))
				print(" - `$(key)`")
				if haskey(keytext, key)
					println(" : $(keytext[key])")
				else
					println("")
				end
			end
		end
	end
	stdoutcaptureoff()
end

function getfunctionarguments(f::Function)
	m = methods(f)
	getfunctionarguments(f, string.(collect(m.ms)))
end
function getfunctionarguments(f::Function, m::Vector{String})
	l = length(m)
	mp = Array{Symbol}(0)
	for i in 1:l
		r = match(r"(.*)\(([^;]*);(.*)\)", m[i])
		if typeof(r) == Void
			r = match(r"(.*)\((.*)\)", m[i])
		end
		if typeof(r) != Void && length(r.captures) > 1
			fargs = strip.(split(r.captures[2], ", "))
			for j in 1:length(fargs)
				if !contains(string(fargs[j]), "...") && fargs[j] != ""
					push!(mp, fargs[j])
				end
			end
		end
	end
	return sort(unique(mp))
end

function getfunctionkeywords(f::Function)
	m = methods(f)
	getfunctionkeywords(f, string.(collect(m.ms)))
end
function getfunctionkeywords(f::Function, m::Vector{String})
	# getfunctionkeywords(f::Function) = methods(methods(f).mt.kwsorter).mt.defs.func.lambda_template.slotnames[4:end-4]
	l = length(m)
	mp = Array{Symbol}(0)
	for i in 1:l
		r = match(r"(.*)\(([^;]*);(.*)\)", m[i])
		if typeof(r) != Void && length(r.captures) > 2
			kwargs = strip.(split(r.captures[3], ", "))
			for j in 1:length(kwargs)
				if !contains(string(kwargs[j]), "...") && kwargs[j] != ""
					push!(mp, kwargs[j])
				end
			end
		end
	end
	return sort(unique(mp))
end

@doc """
$(DocumentFunction.documentfunction(documentfunction; 
maintext="Create function documentation",
argtext=Dict("f"=>"Function to be documented"),
keytext=Dict("maintext"=>"Function description",
             "argtext"=>"Dictionary with text for each argument",
             "keytext"=>"Dictionary with text for each keyword",
             "location"=>"Boolean to show/hide function location on the disk")))
""" documentfunction

@doc """
$(DocumentFunction.documentfunction(getfunctionarguments; 
maintext="Get function arguments",
argtext=Dict("f"=>"Function to be documented",
             "m"=>"Function methods")))
""" getfunctionarguments

@doc """
$(DocumentFunction.documentfunction(getfunctionkeywords; 
maintext="Get function keywords",
argtext=Dict("f"=>"Function to be documented",
             "m"=>"Function methods")))
""" getfunctionkeywords

end