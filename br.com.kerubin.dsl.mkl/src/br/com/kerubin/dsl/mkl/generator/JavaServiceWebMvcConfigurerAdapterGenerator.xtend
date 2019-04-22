package br.com.kerubin.dsl.mkl.generator

import static br.com.kerubin.dsl.mkl.generator.Utils.*

class JavaServiceWebMvcConfigurerAdapterGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		val basePakage = serverGenSourceFolder
		val fileName = basePakage + service.servicePackagePath + '/' + service.toServiceWebMvcConfigurerAdapterName  + '.java'
		generateFile(fileName, generateCORS)
	}
	
	def CharSequence generateCORS() {
		'''
		package «service.servicePackage»;
		
		import org.springframework.context.annotation.ComponentScan;
		import org.springframework.context.annotation.Configuration;
		import org.springframework.web.servlet.config.annotation.EnableWebMvc;
		import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
		import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;
		
		@EnableWebMvc
		@Configuration
		@ComponentScan("br.com.kerubin.api")
		public class «service.toServiceWebMvcConfigurerAdapterName» implements WebMvcConfigurer  {
			
			@Override
			public void addInterceptors(InterceptorRegistry registry) {
				registry.addInterceptor(new ServiceHandlerInterceptorAdapter());
			}
		
		}

		'''
	}
	
}