
solution "netcode"
    kind "ConsoleApp"
    language "C"
    configurations { "Debug", "Release" }
    includedirs { "sodium" }
    rtti "Off"
    warnings "Extra"
    staticruntime "On"
    floatingpoint "Fast"
    filter "configurations:Debug"
        symbols "On"
        defines { "NETCODE_DEBUG" }
    filter "configurations:Release"
        symbols "Off"
        optimize "Speed"
        defines { "NETCODE_RELEASE" }

project "sodium"
    kind "StaticLib"
    files {
        "sodium/**.c",
        "sodium/**.h",
    }
    filter { "system:not windows", "platforms:*x64 or *avx or *avx2" }
        files {
            "sodium/**.S"
        }
    filter { "action:gmake" }
        buildoptions { "-Wno-unused-parameter", "-Wno-unused-function", "-Wno-unknown-pragmas", "-Wno-unused-variable", "-Wno-type-limits" }

project "test"
    files { "test.cpp" }
    links { "sodium" }

project "soak"
    files { "soak.c", "netcode.c" }
    links { "sodium" }

project "profile"
    files { "profile.c", "netcode.c" }
    links { "sodium" }

project "client"
    files { "client.c", "netcode.c" }
    links { "sodium" }

project "server"
    files { "server.c", "netcode.c" }
    links { "sodium" }

project "client_server"
    files { "client_server.c", "netcode.c" }
    links { "sodium" }

if os.ishost "windows" then

    -- Windows

    newaction
    {
        trigger     = "solution",
        description = "Create and open the netcode solution",
        execute = function ()
            os.execute "premake5 vs2019"
            os.execute "start netcode.sln"
        end
    }

else

    -- MacOSX and Linux.
    
    newaction
    {
        trigger     = "test",
        description = "Build and run all unit tests",
        execute = function ()
            os.execute "test ! -e Makefile && premake5 gmake"
            if os.execute "make -j32 test" then
                os.execute "./bin/test"
            end
        end
    }

    newaction
    {
        trigger     = "soak",
        description = "Build and run soak test",
        execute = function ()
            os.execute "test ! -e Makefile && premake5 gmake"
            if os.execute "make -j32 soak" then
                os.execute "./bin/soak"
            end
        end
    }

    newaction
    {
        trigger     = "profile",
        description = "Build and run profile tet",
        execute = function ()
            os.execute "test ! -e Makefile && premake5 gmake"
            if os.execute "make -j32 profile" then
                os.execute "./bin/profile"
            end
        end
    }

    newaction
    {
        trigger     = "client",
        description = "Build and run the client",
        execute = function ()
            os.execute "test ! -e Makefile && premake5 gmake"
            if os.execute "make -j32 client" then
                os.execute "./bin/client"
            end
        end
    }

    newaction
    {
        trigger     = "server",
        description = "Build and run the server",
        execute = function ()
            os.execute "test ! -e Makefile && premake5 gmake"
            if os.execute "make -j32 server" then
                os.execute "./bin/server"
            end
        end
    }

    newaction
    {
        trigger     = "client_server",
        description = "Build and run the client/server testbed",
        execute = function ()
            os.execute "test ! -e Makefile && premake5 gmake"
            if os.execute "make -j32 client_server" then
                os.execute "./bin/client_server"
            end
        end
    }

    newaction
    {
        trigger     = "docker",
        description = "Build and run a netcode server inside a docker container",
        execute = function ()
            os.execute "docker run --rm --privileged alpine hwclock -s" -- workaround for clock getting out of sync on macos. see https://docs.docker.com/docker-for-mac/troubleshoot/#issues
            os.execute "rm -rf docker/netcode && mkdir -p docker/netcode && cp *.h docker/netcode && cp *.c docker/netcode && cp *.cpp docker/netcode && cp premake5.lua docker/netcode && cd docker && docker build -t \"networkprotocol:netcode-server\" . && rm -rf netcode && docker run -ti -p 40000:40000/udp networkprotocol:netcode-server"
        end
    }

    newaction
    {
        trigger     = "valgrind",
        description = "Run valgrind over tests inside docker",
        execute = function ()
            os.execute "rm -rf valgrind/netcode && mkdir -p valgrind/netcode && cp *.h valgrind/netcode && cp *.c valgrind/netcode && cp *.cpp valgrind/netcode && cp premake5.lua valgrind/netcode && cd valgrind && docker build -t \"networkprotocol:netcode-valgrind\" . && rm -rf netcode && docker run -ti networkprotocol:netcode-valgrind"
        end
    }

    newaction
    {
        trigger     = "stress",
        description = "Launch 256 client instances to stress test the server",
        execute = function ()
            os.execute "test ! -e Makefile && premake5 gmake"
            if os.execute "make -j32 client" then
                for i = 0, 255 do
                    os.execute "./bin/client &"
                end
            end
        end
    }

    newaction
    {
        trigger     = "cppcheck",
        description = "Run cppcheck over the source code",
        execute = function ()
            os.execute "cppcheck netcode.c"
        end
    }

    newaction
    {
        trigger     = "scan-build",
        description = "Run clang scan-build over the project",
        execute = function ()
            os.execute "premake5 clean && premake5 gmake && scan-build make all -j32"
        end
    }

    newaction
    {
        trigger     = "loc",
        description = "Count lines of code",
        execute = function ()
            os.execute "wc -l *.h *.c *.cpp"
        end
    }

end

newaction
{
    trigger     = "clean",

    description = "Clean all build files and output",

    execute = function ()

        files_to_delete = 
        {
            "Makefile",
            "*.make",
            "*.txt",
            "*.zip",
            "*.tar.gz",
            "*.db",
            "*.opendb",
            "*.vcproj",
            "*.vcxproj",
            "*.vcxproj.user",
            "*.vcxproj.filters",
            "*.sln",
            "*.xcodeproj",
            "*.xcworkspace"
        }

        directories_to_delete = 
        {
            "obj",
            "ipch",
            "bin",
            ".vs",
            "Debug",
            "Release",
            "release",
            "cov-int",
            "docs",
            "xml",
            "docker/netcode",
            "valgrind/netcode"
        }

        for i,v in ipairs( directories_to_delete ) do
          os.rmdir( v )
        end

        if not os.ishost "windows" then
            os.execute "find . -name .DS_Store -delete"
            for i,v in ipairs( files_to_delete ) do
              os.execute( "rm -f " .. v )
            end
        else
            for i,v in ipairs( files_to_delete ) do
              os.execute( "del /F /Q  " .. v )
            end
        end

    end
}
