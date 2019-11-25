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
		
		import java.util.List;
		
		import org.springframework.context.annotation.ComponentScan;
		import org.springframework.context.annotation.Configuration;
		import org.springframework.format.FormatterRegistry;
		import org.springframework.http.converter.HttpMessageConverter;
		import org.springframework.http.converter.json.MappingJackson2HttpMessageConverter;
		import org.springframework.web.servlet.config.annotation.EnableWebMvc;
		import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
		import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;
		
		import com.fasterxml.jackson.databind.SerializationFeature;
		
		@EnableWebMvc
		@Configuration
		@ComponentScan("br.com.kerubin.api")
		public class «service.toServiceWebMvcConfigurerAdapterName» implements WebMvcConfigurer  {
			
			@Override
			public void addInterceptors(InterceptorRegistry registry) {
				registry.addInterceptor(new ServiceHandlerInterceptorAdapter());
			}
			
			@Override
		    public void extendMessageConverters(List<HttpMessageConverter<?>> converters) { 
		        for (HttpMessageConverter<?> converter : converters) {
		            if (converter instanceof MappingJackson2HttpMessageConverter) {
		                MappingJackson2HttpMessageConverter jsonMessageConverter = (MappingJackson2HttpMessageConverter) converter;
		                com.fasterxml.jackson.databind.ObjectMapper objectMapper = jsonMessageConverter.getObjectMapper();
		                objectMapper.disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);
		                break;
		            }
		        }
		    }
		    
		    @Override
			public void addFormatters(FormatterRegistry registry) {
				registry.addConverter(new MapConverter());
				WebMvcConfigurer.super.addFormatters(registry);
			}
		
		}

		'''
	}
	
}