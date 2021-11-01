package com.plusitsolution.zeenReport.service;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.Reader;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.plusitsolution.common.toolkit.PlusCSVBuilder;
import com.plusitsolution.common.toolkit.PlusCSVUtils;
import com.plusitsolution.common.toolkit.PlusJsonUtils;
import com.plusitsolution.zeenReport.domain.SKUDomain;



@Service
public class ReportService {
	
	@SuppressWarnings("unchecked")
	public byte[] getConvert(MultipartFile uploadfile) throws IOException{

		Map<String, Map<String, Integer>> registerMap = new HashMap<>();
		List<String> allCategories = new ArrayList<>();
		String[] headers = new String[] {"shopID", "SHELF_SHARE"};
		Reader inputFile = new InputStreamReader(uploadfile.getInputStream());
		/*Create csv and read the input file*/
		PlusCSVBuilder csv = PlusCSVUtils.csv("");
		List<String[]> lines = PlusCSVUtils.readCSV(headers, inputFile, true);
		/*Break down SHELF_SHARE*/
		for (String[] value : lines){
			String shopID = value[0];
			String SHELF_SHARE = value[1];
			String productName = null;
			ObjectMapper mapper = new ObjectMapper();
			if (!SHELF_SHARE.isEmpty() && SHELF_SHARE != null) {
				Map<String, Integer> skuMap = registerMap.get(shopID);
				if (skuMap == null) {
					skuMap = new HashMap<>();
					registerMap.put(shopID, skuMap);
				}
				Map<String ,Object> shelfShareMap = mapper.readValue(SHELF_SHARE, Map.class);
				Map<String, Map<String, Integer>> skuCountsMap = (Map<String, Map<String, Integer>>) shelfShareMap.get("skuCounts");
				/*Break down categories into each product*/
				for (Map.Entry<String, Map<String, Integer>> productCategoriesMap : skuCountsMap.entrySet()) {
					Map<String, Integer> productMap = productCategoriesMap.getValue();
					/*Create all categories*/
		            for (Map.Entry<String, Integer> productEntry: productMap.entrySet()) {
		            	StringBuffer name = new StringBuffer();
		            	productName = name.append(productCategoriesMap.getKey()).append(".").append(productEntry.getKey()).toString();
		            	if(!allCategories.contains(productName)) {
		                	allCategories.add(productName);
		                }	
		            	Integer productValue = productMap.get(productName);
		    			if (productValue == null || productEntry.getValue() > productValue) {
		    				skuMap.put(productName, productEntry.getValue());
		    			}
		            } 
		        }
			}
	    }
		
		/*Create result column header*/
		allCategories.add(0 , "shopID");
		csv.headers(allCategories.toArray(new String[0]));
		
		/*Write the result into file*/
		for(Map.Entry<String, Map<String, Integer>> entry : registerMap.entrySet()){
			Map<String, Integer> productMap = entry.getValue();
			Object[] shopInfo = new String[allCategories.size()];
			for(String list : allCategories) {
				//System.out.println(productMap.get(list));
				System.out.println(list + allCategories.indexOf(list));
				if(productMap.get(list) == null) {
					shopInfo[allCategories.indexOf(list)] = "0";
				}
				else {
					shopInfo[allCategories.indexOf(list)] = String.valueOf(productMap.get(list));
				}
			}
			shopInfo[0] = entry.getKey().toString();
			csv.line(shopInfo);
		}
		return csv.writeBytes();
	}

	public byte[] getConvert2(MultipartFile uploadfile) throws IOException{
		List<String[]> inputContent = readCSV(uploadfile);
		//Map<String, SKUDomain> shopSKUMap = identifyData(inputContent);
		//return writeData(shopSKUMap);
		return null;
	}
	
	public List<String[]> readCSV(MultipartFile uploadfile) throws IOException {
		String[] headers = new String[] {"shopID", "SHELF_SHARE"};
		Reader inputFile = new InputStreamReader(uploadfile.getInputStream());
		/*Create csv and read the input file*/
		return PlusCSVUtils.readCSV(headers, inputFile, true);

	}
	
	public Map<String, Map<String, Integer>> identifyData(List<String[]> inputContent){
		Map<String, Map<String, Integer>> resultMap = new HashMap<>();
		for (String[] input : inputContent){
			String shopID = input[0];
			String shelfShare = input[1];
			if(resultMap.containsKey(shopID)) {
				SKUDomain newSKU = PlusJsonUtils.convertToJsonObject(SKUDomain.class, shelfShare);
				resultMap.forEach((k,v) -> {
					newSKU.getSkuCounts().forEach((k2,v2) -> {
						v2.forEach((k3,v3) -> {
							if(v.containsKey(k3)) {
								if(v3 > v.get(k3)) {
									resultMap.get(shopID).put(k3, v3);
								}
							}
							else {
								resultMap.get(shopID).put(k3, v3);
							}
								
						});
					});
				});
				
			}
			else {
				PlusJsonUtils.convertToJsonObject(SKUDomain.class, shelfShare).getSkuCounts().forEach((k,v) -> {
					resultMap.put(shopID,v);
				});
			}
			
		}
		return resultMap;
	}
	
	public byte[] writeData(Map<String, Map<String, Integer>> resultMap) {
		List<String> allCategories = new ArrayList<>();
		PlusCSVBuilder csv = PlusCSVUtils.csv("");
		
		
		
		/*Create result column header*/
		allCategories.add(0 , "shopID");
		
//		resultMap.forEach((k,v) -> {
//			if(!allCategories.contains(productName)) {
//            	allCategories.add(productName);
//            }	
//		});
		
		csv.headers(allCategories.toArray(new String[0]));
		
		/*Write the result into file*/
		for(Map.Entry<String, Map<String, Integer>> entry : resultMap.entrySet()){
			Map<String, Integer> productMap = entry.getValue();
			Object[] shopInfo = new String[allCategories.size()];
			for(String list : allCategories) {
				//System.out.println(productMap.get(list));
				System.out.println(list + allCategories.indexOf(list));
				if(productMap.get(list) == null) {
					shopInfo[allCategories.indexOf(list)] = "0";
				}
				else {
					shopInfo[allCategories.indexOf(list)] = String.valueOf(productMap.get(list));
				}
			}
			shopInfo[0] = entry.getKey().toString();
			csv.line(shopInfo);
		}
		return csv.writeBytes();
	}
	
//	public static void main(String[] args) {
//		String rs = "{\"skuCounts\":{\"UHT\":{\"BEAR_BRAND_ORIGINAL_BOX_180ML\":0,\"MILO_LOW_SUGAR_BOX_180ML\":0,\"CARNATION_BOX_180ML\":0,\"MILO_ORIGINAL_BOX_180ML\":0,\"BEAR_BRAND_HONEY_BOX_180ML\":0,\"OVALTINE_BOX_180ML\":0,\"BEAR_BRAND_MALTED_MILK_BOX_180ML\":0,\"DMALT_BOX_180ML\":0,\"FOREMOST_BOX_225ML\":0,\"FOREMOST_OMEGA_BOX_180ML\":0},\"RTD_TEA\":{\"NESTEA\":0},\"CLC\":{\"NESCAFE_BLACK_ICE_CAN_180ML\":0,\"BIRDY_BLACK_CAN_180ML\":0,\"BIRDY_ROBUSTA_LOW_SUGAR_CAN_180ML\":0,\"NESCAFE_BLACK_ROAST\":0,\"NESCAFE_ESPRESSO_CAN_180ML\":0,\"NESCAFE_LATTE_CAN_180ML\":0,\"BIRDY_ESPRESSO_CAN_180ML\":0,\"BIRDY_LATTE_CAN_180ML\":0,\"NESCAFE_TRIPLE\":0,\"CARABAO_ESPRESSO_CAN_180ML\":0,\"BIRDY_BLACK_LOW_SUGAR_CAN_180ML\":0,\"BIRDY_ROBUSTA_CAN_180ML\":0},\"WATER\":{\"NARMTHIP_550ML\":0,\"NESTLE_PURELIFE_600ML\":0,\"CRYSTAL_600ML\":0,\"SINGHA_600ML\":0}}}";
//		SKUDomain skuSomain = PlusJsonUtils.convertToJsonObject(SKUDomain.class, rs);
//		Map<String, SKUDomain> shopSKUMap = new HashMap<>();
//		System.out.println(skuSomain);
//	}
}
