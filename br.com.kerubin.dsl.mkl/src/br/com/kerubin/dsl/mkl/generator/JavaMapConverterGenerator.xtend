package br.com.kerubin.dsl.mkl.generator

import static br.com.kerubin.dsl.mkl.generator.Utils.*

class JavaMapConverterGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		val basePakage = serverGenSourceFolder
		val fileName = basePakage + service.servicePackagePath + '/' + service.toServiceMapConverterName  + '.java'
		generateFile(fileName, generateMapConverter)
	}
	
	def CharSequence generateMapConverter() {
		'''
		package «service.servicePackage»;
		
		import java.io.IOException;
		import java.util.Collections;
		import java.util.Map;
		
		import org.springframework.core.convert.converter.Converter;
		
		import com.fasterxml.jackson.databind.ObjectMapper;
		
		import lombok.extern.slf4j.Slf4j;
		
		@Slf4j
		public class «service.toServiceMapConverterName» implements Converter<String, Map<Object, Object>> {
			
			@SuppressWarnings("unchecked")
			@Override
			public Map<Object, Object> convert(String jsonAsString) {
				if (jsonAsString != null) {
					jsonAsString = jsonAsString.trim();
					if (!jsonAsString.isEmpty()) {
						ObjectMapper mapper = new ObjectMapper();
						try {
							Map<Object, Object> result = mapper.readValue(jsonAsString, Map.class);
							return result;
						} catch (IOException e) {
							log.error("Error mapping JSON as String parameter to a Map<Object, Object>.");
						}
					}
				}
				
				return Collections.emptyMap();
			}
		
		}

		'''
	}
	
}