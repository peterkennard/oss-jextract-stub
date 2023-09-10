myDir = File.expand_path(File.dirname(__FILE__));
require "#{myDir}/../build-options.rb"
require "rakish/GitModule"

depends=[
]

Rakish.Project(
    :includes=>[Rakish::CppProjectModule, Rakish::GitModule ],
	:name 		=> "oss-jextract",
	:dependsUpon => [ depends ]
) do

    setSourceSubdir("#{projectDir}/jextract");

    if(targetPlatform =~ /MacOS/)
        set(:jextractPath, "#{sourceSubdir}/build/jextract/bin/jextract");
    elsif(targetPlatform =~ /Windows/)
        set(:jextractPath, "#{projectDir}/jextract-20/bin/jextract");
    end

    pubTargs = task :publicTargets;

	file sourceSubdir do |t|
		git.clone('https://github.com/openjdk/jextract.git', t.name );
	end

    iTask = task :includes => [ sourceSubdir ] do
    end

    builtUtils = file "#{sourceSubdir}/build/jextract/bin/jextract" => sourceSubdir do |t|

        oJHome = ENV['JAVA_HOME' ]
        begin
            FileUtils.cd sourceSubdir do
                if(targetPlatform =~ /MacOS/)
                    ENV['JAVA_HOME'] = "/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home"
                    system("chmod +x #{sourceSubdir}/gradlew");

                    cmd = "./gradlew"
                    cmd += " -Pjdk20_home=/Library/Java/JavaVirtualMachines/zulu-20.jdk/Contents/Home"
                    cmd += " -Pllvm_home=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/"
                    cmd += " clean verify"

                    system(cmd);
                elsif(targetPlatform =~ /Windows/)

                    # https://download.java.net/java/early_access/jextract/1/openjdk-20-jextract+1-2_windows-x64_bin.tar.gz
                end
            end
        rescue
            log.error("unable to build #{t.name}");
        ensure
            ENV['JAVA_HOME'] = oJHome;
        end
    end

    export task :vendorLibs => [ builtUtils ] do
    end

    export task :genProject => :vendorLibs

    export task :cleanAll => sourceSubdir do |t|
        FileUtils.rm_rf("#{buildDir}/include/glm");  # remove recursive
        FileUtils.cd sourceSubdir do
            system('git reset --hard');  # Maybe delete and re-download - though a bit slow
        end
    end

end

