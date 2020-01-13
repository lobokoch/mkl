package br.com.kerubin.dsl.mkl.generator

import static extension br.com.kerubin.dsl.mkl.generator.Utils.*

class JavaServiceConfigGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		val basePakage = serverGenSourceFolder
		val fileName = basePakage + service.servicePackagePath + '/ServiceConfig.java'
		generateFile(fileName, generateServiceConfig)
	}
	
	def CharSequence generateServiceConfig() {
		
		'''
		package «service.servicePackage»;
		
		import org.springframework.boot.context.properties.ConfigurationProperties;
		import org.springframework.context.annotation.Configuration;
		import org.springframework.core.Ordered;
		import org.springframework.core.annotation.Order;
		
		import lombok.Getter;
		import lombok.Setter;
		import lombok.ToString;
		
		@Order(Ordered.HIGHEST_PRECEDENCE)
		@Configuration
		@ConfigurationProperties("kerubin.web")
		@Getter
		@Setter
		@ToString
		public class ServiceConfig {
			
			private static final String ALLOW_ORIGINS = "http://localhost:4200";
			
			private String allowOrigin;
			private boolean enableHttps;
			
			public ServiceConfig() {
				this.allowOrigin = ALLOW_ORIGINS;
			}
		
		}
		
		'''
	}
	
}