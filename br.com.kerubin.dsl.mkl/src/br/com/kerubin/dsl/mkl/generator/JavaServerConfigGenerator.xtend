package br.com.kerubin.dsl.mkl.generator

import static extension br.com.kerubin.dsl.mkl.generator.Utils.*

class JavaServerConfigGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		val basePakage = serverGenSourceFolder
		val fileName = basePakage + service.servicePackagePath + '/ServerConfig.java'
		generateFile(fileName, generateServerConfig)
	}
	
	def CharSequence generateServerConfig() {
		'''
		package «service.servicePackage»;
		
		import org.modelmapper.ModelMapper;
		import org.modelmapper.convention.MatchingStrategies;
		import org.springframework.context.annotation.Bean;
		import org.springframework.context.annotation.Configuration;
		
		@Configuration
		public class ServerConfig {
			
			@Bean
			public ModelMapper modelMapper() {
				ModelMapper modelMapper = new ModelMapper();
				modelMapper.getConfiguration().setMatchingStrategy(MatchingStrategies.STRICT);
				return modelMapper;
			}
		}
		'''
	}
	
}