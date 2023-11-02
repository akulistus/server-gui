# code from https://github.com/Gnimuc/CImGui.jl/blob/master/examples/Renderer.jl with addition of ImPlot couple of functions
module Renderer

using CImGui
using CImGui.ImGuiGLFWBackend
using CImGui.ImGuiOpenGLBackend
using CImGui.ImGuiGLFWBackend.LibGLFW
using CImGui.ImGuiOpenGLBackend.ModernGL
using ImPlot
using CImGui.CSyntax
import CImGui.ImGuiGLFWBackend: ImGui_ImplGlfw_ErrorCallback

function __init__()
    # @static if Sys.isapple()
    #     # OpenGL 3.2 + GLSL 150
    #     global glsl_version = 150
    #     glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3)
    #     glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 2)
    #     glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE) # 3.2+ only
    #     glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE) # required on Mac
    # else
    #     # OpenGL 3.0 + GLSL 130
    #     global glsl_version = 130
    #     glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3)
    #     glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 0)
    #     # glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE) # 3.2+ only
    #     # glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE) # 3.0+ only
    # end
    glfwDefaultWindowHints()
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3)
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 2)
    @static if Sys.isapple()
        global glsl_version = 150
        glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE) # 3.2+ only
        glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, true) # required on Mac
    else
        global glsl_version = 130 # ???
    end

end

#? error_callback(err::GLFW.GLFWError) = @error "GLFW ERROR: code $(err.code) msg: $(err.description)"

function init_renderer(width, height, title::AbstractString)

    glfwSetErrorCallback(@cfunction(ImGui_ImplGlfw_ErrorCallback, Cvoid, (Cint, Ptr{Cchar})))

    # create window
    window = glfwCreateWindow(width, height, title, C_NULL, C_NULL)
    @assert window != C_NULL
    glfwMakeContextCurrent(window)
    glfwSwapInterval(1)  # enable vsync

    # setup Dear ImGui context
    ctx = CImGui.CreateContext()
    ctxp = ImPlot.CreateContext()
    ImPlot.SetImGuiContext(ctx)

    # setup Dear ImGui style
    CImGui.StyleColorsDark()
    # CImGui.StyleColorsClassic()
    # CImGui.StyleColorsLight()

    # setup Platform/Renderer bindings
    glfw_ctx = ImGuiGLFWBackend.create_context(window, install_callbacks = true)
    opengl_ctx = ImGuiOpenGLBackend.create_context(glsl_version)

    ImGuiGLFWBackend.init(glfw_ctx)
    ImGuiOpenGLBackend.init(opengl_ctx)

    # enable docking
    io = CImGui.GetIO()
    io.ConfigFlags = unsafe_load(io.ConfigFlags) | CImGui.ImGuiConfigFlags_DockingEnable

    ### DPI для 4К-дисплеев
    # basic_h = 1080 # basic_w 1920
    # mode = glfwGetVideoMode(glfwGetPrimaryMonitor())
    # w = unsafe_load(mode).width
    # h = unsafe_load(mode).height
    # dpi_scale = h / basic_h
    # @info dpi_scale
    # # @show h w

	# style = CImGui.GetStyle()
    # CImGui.LibCImGui.ImGuiStyle_ScaleAllSizes(style, dpi_scale)
    # # io.FontGlobalScale = dpi_scale; - скорее всего лишнее

    ### ШРИФТЫ
    fonts = unsafe_load(io.Fonts)
    ranges = CImGui.GetGlyphRangesCyrillic(fonts)
    CImGui.AddFontFromFileTTF(fonts, "C:\\Windows\\Fonts\\tahoma.ttf", 16, C_NULL, ranges);


    return window, ctx, glfw_ctx, opengl_ctx
end

function renderloop(window, ctx, glfw_ctx, opengl_ctx, ui=()->nothing, hotloading=false)
    try
        while glfwWindowShouldClose(window) == 0
            glfwPollEvents()
            ImGuiOpenGLBackend.new_frame(opengl_ctx)
            ImGuiGLFWBackend.new_frame(glfw_ctx)
            CImGui.NewFrame()

            hotloading ? Base.invokelatest(ui) : ui()

            CImGui.Render()
            glfwMakeContextCurrent(window)

            width, height = Ref{Cint}(), Ref{Cint}() #! need helper fcn
            glfwGetFramebufferSize(window, width, height)
            display_w = width[]
            display_h = height[]

            glViewport(0, 0, display_w, display_h)
            glClearColor(0.2, 0.2, 0.2, 1)
            glClear(GL_COLOR_BUFFER_BIT)
            ImGuiOpenGLBackend.render(opengl_ctx) #ImGui_ImplOpenGL3_RenderDrawData(CImGui.GetDrawData())

            #glfwMakeContextCurrent(window)
            glfwSwapBuffers(window)
            yield()
        end
    catch e
        @error "Error in renderloop!" exception=e
        Base.show_backtrace(stderr, catch_backtrace())
    finally
        ImGuiOpenGLBackend.shutdown(opengl_ctx) #ImGui_ImplOpenGL3_Shutdown()
        ImGuiGLFWBackend.shutdown(glfw_ctx) #ImGui_ImplGlfw_Shutdown()
        CImGui.DestroyContext(ctx)
        glfwDestroyWindow(window)
    end
end

function render(ui; width=1280, height=720, title::AbstractString="Demo", hotloading=false)
    window, ctx, glfw_ctx, opengl_ctx = init_renderer(width, height, title)
    GC.@preserve window ctx begin
        t = @async renderloop(window, ctx, glfw_ctx, opengl_ctx, ui, hotloading)
    end
    return t
end

end # module