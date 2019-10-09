package br.com.kerubin.dsl.mkl.generator

import static extension br.com.kerubin.dsl.mkl.generator.Utils.*

class JavaSwaggerConfigGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	private static val SWAGGER2_CONFIG_NAME = 'Swagger2Config'
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		val basePakage = serverGenSourceFolder
		val fileName = basePakage + service.servicePackagePath + '/' + SWAGGER2_CONFIG_NAME + '.java'
		generateFile(fileName, generateSwaggerConfig)
	}
	
	def CharSequence generateSwaggerConfig() {
		
		val apiVersion = configuration.version ?: '0.0.1-SNAPSHOT'
		val doc = configuration.springfoxSwagger
		
		var title = '''API documentation for «service.domain»/«service.name»'''
		var description = '''This API documentation describes all available operations over service /api/«service.domain»/«service.name»/*''' 
		if (doc !== null) {
			if (doc.description !== null) {
				description = doc.description
			}
			
			if (doc.title !== null) {
				title = doc.title
			}
		}
		
		'''
		package «service.servicePackage»;
		
		import org.springframework.context.annotation.Bean;
		import org.springframework.context.annotation.Configuration;
		import org.springframework.context.annotation.Import;
		import org.springframework.web.servlet.config.annotation.EnableWebMvc;
		import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
		import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;
		
		import springfox.documentation.builders.ApiInfoBuilder;
		import springfox.documentation.builders.PathSelectors;
		import springfox.documentation.builders.RequestHandlerSelectors;
		import springfox.documentation.service.ApiInfo;
		import springfox.documentation.spi.DocumentationType;
		import springfox.documentation.spring.web.plugins.Docket;
		import springfox.documentation.swagger2.annotations.EnableSwagger2;
		
		@Configuration
		@EnableSwagger2
		@EnableWebMvc
		@Import({ springfox.bean.validators.configuration.BeanValidatorPluginsConfiguration.class })
		public class «SWAGGER2_CONFIG_NAME» {
		
			@Bean
			public Docket api() {
				return new Docket(DocumentationType.SWAGGER_2)
					.select()
					.apis(RequestHandlerSelectors.any())
					.paths(PathSelectors.any())
					.build()
					.apiInfo(apiInfo());
			}
		
			private ApiInfo apiInfo() {
				return new ApiInfoBuilder()
					.title("«title»")
					.description("«description»")
					.version("«apiVersion»")
					.build();
			}
		
			@Bean
			public WebMvcConfigurer webMvcConfigurer() {
				return new WebMvcConfigurer() {
					
					@Override
					public void addResourceHandlers(ResourceHandlerRegistry registry) {
						registry.addResourceHandler("swagger-ui.html")
							.addResourceLocations("classpath:/META-INF/resources/");
						
						registry.addResourceHandler("/webjars/**")
							.addResourceLocations("classpath:/META-INF/resources/webjars/");
					}
				};
			}
		
		}
		
		'''
	}
	
}